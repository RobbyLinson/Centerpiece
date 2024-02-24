import os
import json

def save_entry_to_file(title, message, summary):
    entry = {
        "title": title,
        "message": message,
        "summary": summary
    }
    output_folder = "summaries"
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

if __name__ == "__main__":
    # Example usage
    save_entry_to_file("Sample Title", "This is a sample message.", "This is a summary.")
