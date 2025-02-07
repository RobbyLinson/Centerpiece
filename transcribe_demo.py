#! python3.7
# 
# import keyboard
import json
import argparse
import os
import numpy as np
import speech_recognition as sr
import whisper
import torch
import torch.cuda

from datetime import datetime, timedelta
from queue import Queue
from time import sleep
from sys import platform

def save_entry_to_file(title, message, summary):
    entry = {
        "title": title,
        "message": message,
        "summary": summary
    }
    output_folder = "centerpiece/assets/summaries"
    os.makedirs(output_folder, exist_ok=True)

    index_file_path = os.path.join(output_folder, "index.txt")
    # Read the current index from the index file or set it to 1 if the file doesn't exist
    if os.path.exists(index_file_path):
        with open(index_file_path, 'r') as index_file:
            index = int(index_file.read())
    else:
        index = 1
        
    entry_file_path = os.path.join(output_folder, f"{index}.json")



    # Write the entry to a JSON file
    with open(entry_file_path, 'w') as entry_file:
        json.dump(entry, entry_file, indent=2)

    # Update the index in the index file
    index += 1
    with open(index_file_path, 'w') as index_file:
        index_file.write(str(index))
    
    # OpenAI API
    # Takes in a transcriptions
    # Returns a summary of the transcription        

def make_request(final_transcription, prompt_type):         
    from openai import OpenAI
    client = OpenAI()
    if prompt_type == "speech":
        prompt = "Summarize this speech."
    elif prompt_type == "flashcards":
        prompt = "Turn this speech into flashcards. Specifically in a JSON format with front and back fields."
    elif prompt_type == "key":
        prompt = "Write down the key main points of this speech."
    else:
        prompt = "Summarize this speech."


    completion = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": "You are a summarizer, skilled in explaining speeches in an easy to understand way."},
        {"role": "user", "content": final_transcription + prompt + "Please note there may be some errors in the transcription." + "Please do not be afraid to add in contextually relevant information."},
    ]
    )

    print(completion.choices[0].message)
    return completion.choices[0].message.content

def transcribe_and_summarize():

    output_folder = "centerpiece/assets/summaries"
    os.makedirs(output_folder, exist_ok=True)

    # Use a timestamp to generate unique filenames
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    output_file_path = os.path.join(output_folder, f"output_{timestamp}.json")

    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="medium", help="Model to use",
                        choices=["tiny", "base", "small", "medium", "large"])
    parser.add_argument("--non_english", action='store_true',
                        help="Don't use the english model.")
    parser.add_argument("--energy_threshold", default=600,
                        help="Energy level for mic to detect.", type=int)
    parser.add_argument("--record_timeout", default=7,
                        help="How real time the recording is in seconds.", type=float)
    parser.add_argument("--phrase_timeout", default=1,
                        help="How much empty space between recordings before we "
                             "consider it a new line in the transcription.", type=float)
    if 'linux' in platform:
        parser.add_argument("--default_microphone", default='pulse',
                            help="Default microphone name for SpeechRecognition. "
                                 "Run this with 'list' to view available Microphones.", type=str)
    args = parser.parse_args()

    # The last time a recording was retrieved from the queue.
    phrase_time = None
    # Thread safe Queue for passing data from the threaded recording callback.
    data_queue = Queue()
    # We use SpeechRecognizer to record our audio because it has a nice feature where it can detect when speech ends.
    recorder = sr.Recognizer()
    recorder.energy_threshold = args.energy_threshold
    # Definitely do this, dynamic energy compensation lowers the energy threshold dramatically to a point where the SpeechRecognizer never stops recording.
    recorder.dynamic_energy_threshold = False

    # Important for linux users.
    # Prevents permanent application hang and crash by using the wrong Microphone
    if 'linux' in platform:
        mic_name = args.default_microphone
        if not mic_name or mic_name == 'list':
            print("Available microphone devices are: ")
            for index, name in enumerate(sr.Microphone.list_microphone_names()):
                print(f"Microphone with name \"{name}\" found")
            return
        else:
            print(f"Searching for microphone with name \"{mic_name}\"")
            for index, name in enumerate(sr.Microphone.list_microphone_names()):
                if mic_name in name:
                    source = sr.Microphone(sample_rate=16000, device_index=index)
                    break
    else:
        print("Using default microphone.")
        

        source = sr.Microphone(sample_rate=16000)


    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    
    # Load / Download model
    model = args.model
    if args.model != "large" and not args.non_english:
        model = model + ".en"
    # Load the model and move it to the GPU if available
    audio_model = whisper.load_model(model).to(device)

    record_timeout = args.record_timeout
    phrase_timeout = args.phrase_timeout

    transcription = ['']

    with source:
        recorder.adjust_for_ambient_noise(source)

    def record_callback(_, audio:sr.AudioData) -> None:
        """
        Threaded callback function to receive audio data when recordings finish.
        audio: An AudioData containing the recorded bytes.
        """
        # Grab the raw bytes and push it into the thread safe queue.
        data = audio.get_raw_data()
        data_queue.put(data)

    
    # Create a background thread that will pass us raw audio bytes.
    # We could do this manually but SpeechRecognizer provides a nice helper.
    recorder.listen_in_background(source, record_callback, phrase_time_limit=record_timeout)

    # Cue the user that we're ready to go.
    print("Model loaded.\n")



    # listen to an api request to stop recording
    stop_recording = False

    import keyboard
    # record 
    while not keyboard.is_pressed('q'):
        try:
            now = datetime.utcnow()
            # Pull raw recorded audio from the queue.
            if not data_queue.empty():
                phrase_complete = False
                # If enough time has passed between recordings, consider the phrase complete.
                # Clear the current working audio buffer to start over with the new data.
                if phrase_time and now - phrase_time > timedelta(seconds=phrase_timeout):
                    phrase_complete = True
                # This is the last time we received new audio data from the queue.
                phrase_time = now
                
                # Combine audio data from queue
                audio_data = b''.join(data_queue.queue)
                data_queue.queue.clear()
                
                # Convert in-ram buffer to something the model can use directly without needing a temp file.
                # Convert data from 16 bit wide integers to floating point with a width of 32 bits.
                # Clamp the audio stream frequency to a PCM wavelength compatible default of 32768hz max.
                audio_np = np.frombuffer(audio_data, dtype=np.int16).astype(np.float32) / 32768.0

                # Move the audio data to the GPU if available
                audio_tensor = torch.from_numpy(audio_np).to(device)

                # Read the transcription.
                result = audio_model.transcribe(audio_tensor, fp16=torch.cuda.is_available())
                text = result['text'].strip()

                # If we detected a pause between recordings, add a new item to our transcription.
                # Otherwise edit the existing one.
                if phrase_complete:
                    transcription.append(text)
                else:
                    transcription[-1] = text

                # Clear the console to reprint the updated transcription.
                os.system('cls' if os.name=='nt' else 'clear')
                for line in transcription:
                    print(line)
                # Flush stdout.
                # print('', end='', flush=True)

                # Infinite loops are bad for processors, must sleep.
                sleep(0.25)
        except KeyboardInterrupt:
            # save_entry_to_file("","","");
            break
    
    # Stop the background thread.
    print("\n\nTranscription:")

    final_transcription = ''

    for line in transcription:
        print(line)
        # concatonate the transcription into a single string
        final_transcription += line + ' '
    title = input("What would you like to name the transcription?")
    prompt = input("What would you like to do with the transcription? (flashcards, key, speech)")
    summary = make_request(final_transcription, prompt)
    save_entry_to_file(title, final_transcription, summary)
    input("Press Enter to save the transcription and summary to a file.")


        

if __name__ == "__main__":
    transcribe_and_summarize()
