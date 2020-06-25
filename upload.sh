ZIP_FILE="build.zip"
S3_BUCKET="serverless-deep-learning-example"
S3_KEY="lambdas/resnet50.zip"

FUNCTION_NAME="DeepLearningLambda"

aws s3 cp "${ZIP_FILE}" "s3://${S3_BUCKET}/${S3_KEY}"

aws lambda update-function-code \
    --function-name ${FUNCTION_NAME} \
    --s3-bucket ${S3_BUCKET} \
    --s3-key ${S3_KEY}