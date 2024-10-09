import cv2
import pytesseract
from PIL import Image

# Path to tesseract executable (needed for some systems)
pytesseract.pytesseract.tesseract_cmd = r'/opt/homebrew/bin/tesseract'

# Function to capture barcode information
def extract_barcode(image_path):
    # Load the image
    image = cv2.imread(image_path)
    if image is None:
        raise ValueError(f"Could not open or find the image: {image_path}")

    # Convert to grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Apply thresholding to enhance barcode visibility
    _, thresholded = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    # Use pytesseract to extract text from the thresholded image
    custom_config = r'--oem 3 --psm 6'  # OEM 3 is the default, PSM 6 for sparse text
    barcode_text = pytesseract.image_to_string(thresholded, config=custom_config)

    # Clean the barcode text by removing unwanted characters
    barcode_text = barcode_text.strip().replace("\n", "")

    # Optional: Check if barcode_text is empty or not
    if not barcode_text:
        raise ValueError("No barcode detected in the image.")

    return barcode_text

# Example usage
image_path = 'barcode.png'  # Replace with the actual path to the captured image

# Extract barcode data from the image
barcode_data = extract_barcode(image_path)
print("Extracted Barcode Data:", barcode_data)

# Dictionary to map barcode to item types
barcode_to_item = {
    "1234567890": "Fragile Item",
    "0987654321": "Perishable Item",
    "1122334455": "Heavy Item"
}

# Function to determine storage position based on item type
def get_storage_position(item_type):
    # Example logic for positioning items
    if item_type == "Fragile Item":
        return "Upper Section"
    elif item_type == "Perishable Item":
        return "Near Exit"
    elif item_type == "Heavy Item":
        return "Lower Section"
    else:
        return "General Section"

# Lookup item type based on barcode
item_type = barcode_to_item.get(barcode_data, "Unknown Item")

# Get the appropriate storage position
storage_position = get_storage_position(item_type)

# Display the result
print(f"Item Type: {item_type}")
print(f"Storage Position: {storage_position}")
