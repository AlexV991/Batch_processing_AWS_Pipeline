import zipfile

#zip Lambda function to upload to Lambda
with zipfile.ZipFile("lambda_function.py.zip", "w") as z:
    z.write("lambda_function.py")
