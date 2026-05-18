import os
from PIL import Image

# Path to the source logo
source_logo_path = r"c:\htmlproject\buspass\static\images\b_logo.png"

# Target Android res directory
res_dir = r"c:\htmlproject\buspass\flutter_app\android\app\src\main\res"

# Mipmap folders and their target launcher icon sizes
icon_configs = {
    "mipmap-mdpi": (48, 48),
    "mipmap-hdpi": (72, 72),
    "mipmap-xhdpi": (96, 96),
    "mipmap-xxhdpi": (144, 144),
    "mipmap-xxxhdpi": (192, 192),
}

def resize_and_replace():
    if not os.path.exists(source_logo_path):
        print(f"Error: Source logo not found at {source_logo_path}")
        return

    # Open the source image
    with Image.open(source_logo_path) as img:
        # Convert to RGBA just in case
        img = img.convert("RGBA")
        
        for folder, size in icon_configs.items():
            folder_path = os.path.join(res_dir, folder)
            if not os.path.exists(folder_path):
                os.makedirs(folder_path)
            
            # Target path for ic_launcher.png
            target_path = os.path.join(folder_path, "ic_launcher.png")
            
            # Resize image with high-quality resampling
            resized_img = img.resize(size, Image.Resampling.LANCZOS)
            
            # Save the resized image
            resized_img.save(target_path, "PNG")
            print(f"Successfully created: {target_path} at size {size}")

        print("\nAll Android app launcher icons have been successfully replaced with the CITY PASS logo!")

if __name__ == "__main__":
    resize_and_replace()
