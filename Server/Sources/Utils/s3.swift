import Foundation
import SotoS3

class S3Uploader: @unchecked Sendable {
    let s3: S3
    let bucketName: String
    let region: Region

    init(accessKey: String, secretKey: String, region: Region, bucketName: String) {
        let awsClient = AWSClient(
            credentialProvider: .static(accessKeyId: accessKey, secretAccessKey: secretKey),
            httpClientProvider: .createNew
        )
        s3 = S3(client: awsClient, region: region)
        self.bucketName = bucketName
        self.region = region
    }

    func upload(data: Data, fileExtension: String) async throws -> String {
        let fileKey = "\(UUID().uuidString).\(fileExtension)"

        let putObjectRequest = S3.PutObjectRequest(
            body: .data(data),
            bucket: bucketName,
            key: fileKey
        )

        return try await s3.putObject(putObjectRequest)
            .map { _ in
                self.getPublicURL(for: fileKey)
            }.get()
    }

    func download(fileURL: String) async throws -> Data {
        let getObjectRequest = S3.GetObjectRequest(
            bucket: bucketName,
            key: fileURL
        )

        return try await s3.getObject(getObjectRequest).get().body!.asData()!
    }

    private func getPublicURL(for key: String) -> String {
        "https://\(bucketName).s3.\(region.rawValue).amazonaws.com/\(key)"
    }

    deinit {
        try? s3.client.syncShutdown()
    }
}
