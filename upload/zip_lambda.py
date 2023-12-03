import zipfile

#zip Lambda function to upload to Lambda
with zipfile.ZipFile("upload/lambda_function.py.zip", "w") as z:
    # Füge die Python-Datei hinzu
    z.write("upload/lambda_function.py")
