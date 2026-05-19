import qrcode

url = "https://online-buss-pass-generation-and-renewal.onrender.com/media/app-release.apk"
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
