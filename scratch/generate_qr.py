import qrcode

url = "https://github.com/sowndhariya31/Online-Buss-Pass-Generation-And-Renewal/raw/main/static/app-release.apk"
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=4,
)
qr.add_data(url)
qr.make(fit=True)

img = qr.make_image(fill_color="black", back_color="white")
# Save both to artifacts and to media directory
img.save(r"C:\Users\pooja\.gemini\antigravity\brain\1d5376ef-d157-4638-906a-9e25dea2ccf8\media_qr.png")
img.save(r"c:\htmlproject\buspass\media\media_qr.png")
print("QR Code generated successfully.")
