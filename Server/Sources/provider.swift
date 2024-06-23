import AsyncHTTPClient
import Foundation
import GRPC
import NIO
import NIOHTTP1
import RediStack

let humeApiKey = ProcessInfo.processInfo.environment["HUME_API_KEY"]!
let groqApiKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"]!
let openaiApiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!

func byteBufferToJSON(_ buffer: ByteBuffer) throws -> [String: Any] {
    let data = Data(buffer.readableBytesView)
    return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
}

struct GroqTranscriptionResponse: Codable {
    let text: String
}

func dotProduct(_ embedding1: [Float], _ embedding2: [Float]) -> Double {
    var dotProduct = 0.0
    for (i, _) in embedding1.enumerated() {
        dotProduct += Double(embedding1[i] * embedding2[i])
    }
    return dotProduct
}

func transcribeAudio(audioData: Data, httpClient: HTTPClient) async throws -> String {
    let boundary = UUID().uuidString
    var body = ByteBuffer()

    // Add model field
    body.writeString("--\(boundary)\r\n")
    body.writeString("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
    body.writeString("whisper-large-v3\r\n")

    // Add temperature field
    body.writeString("--\(boundary)\r\n")
    body.writeString("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n")
    body.writeString("0\r\n")

    // Add response_format field
    body.writeString("--\(boundary)\r\n")
    body.writeString("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
    body.writeString("json\r\n")

    // Add language field
    body.writeString("--\(boundary)\r\n")
    body.writeString("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
    body.writeString("en\r\n")

    // Add file field
    body.writeString("--\(boundary)\r\n")
    body.writeString("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n")
    body.writeString("Content-Type: audio/m4a\r\n\r\n")
    body.writeData(audioData)
    body.writeString("\r\n")

    // End of multipart form data
    body.writeString("--\(boundary)--\r\n")

    var headers = HTTPHeaders()
    headers.add(name: "Content-Type", value: "multipart/form-data; boundary=\(boundary)")
    headers.add(name: "Authorization", value: "Bearer \(groqApiKey)")

    let request = try HTTPClient.Request(
        url: "https://api.groq.com/openai/v1/audio/transcriptions",
        method: .POST,
        headers: headers,
        body: .byteBuffer(body)
    )

    let response = try await httpClient.execute(request: request).get()
    let responseData = Data(buffer: response.body!) // 1 MB max

    if response.status == .ok {
        let decodedResponse = try JSONDecoder().decode(GroqTranscriptionResponse.self, from: responseData)
        return decodedResponse.text
    } else {
        throw NSError(domain: "GroqAPI", code: Int(response.status.code), userInfo: [NSLocalizedDescriptionKey: String(data: responseData, encoding: .utf8) ?? "Unknown error"])
    }
}

struct OpenAIEmbeddingResponse: Codable {
    let data: [OpenAIEmbeddingData]

    struct OpenAIEmbeddingData: Codable {
        let embedding: [Float]
    }
}

func getEmbedding(text: String, httpClient: HTTPClient) async throws -> [Float] {
    var headers = HTTPHeaders()
    headers.add(name: "Content-Type", value: "application/json")
    headers.add(name: "Authorization", value: "Bearer \(openaiApiKey)")

    let request = try HTTPClient.Request(
        url: "https://api.openai.com/v1/embeddings",
        method: .POST,
        headers: headers,
        body: .string(#"{"input": "\#(text)", "model": "text-embedding-ada-002"}"#)
    )

    let response = try await httpClient.execute(request: request).get()
    let responseData = Data(buffer: response.body!) // 1 MB max

    if response.status == .ok {
        let decodedResponse = try JSONDecoder().decode(OpenAIEmbeddingResponse.self, from: responseData)
        return decodedResponse.data[0].embedding
    } else {
        throw NSError(domain: "OpenAIAPI", code: Int(response.status.code), userInfo: [NSLocalizedDescriptionKey: String(data: responseData, encoding: .utf8) ?? "Unknown error"])
    }
}

actor EmailToNumberMap {
    var map: [String: Int] = [:]

    func set(email: String, number: Int) {
        map[email] = number
    }

    func get(email: String) -> Int? {
        map[email]
    }

    func increment(email: String) -> Int {
        if let number = map[email] {
            map[email] = number + 1
        } else {
            map[email] = 1
        }
        return map[email]!
    }
}

final class BerkeleychatProvider: Berkeleychat_BerkeleychatAsyncProvider {
    let redis: RedisConnectionPool
    let s3: S3Uploader
    let httpClient: HTTPClient

    init(redis: RedisConnectionPool, s3: S3Uploader, httpClient: HTTPClient) {
        self.redis = redis
        self.s3 = s3
        self.httpClient = httpClient
    }

    func uploadPhoto(request: Berkeleychat_UploadPhotoRequest, context _: GRPCAsyncServerCallContext) async throws -> Berkeleychat_UploadPhotoResponse {
        // TODO: let accessToken = request.accessToken
        let photo = request.photo

        let photoURL = try await s3.upload(data: photo, fileExtension: "jpg")
        print("photoURL", photoURL)
        return Berkeleychat_UploadPhotoResponse.with {
            $0.photoURL = photoURL
        }
    }

    func uploadAudio(request: Berkeleychat_UploadAudioRequest, context _: GRPCAsyncServerCallContext) async throws -> Berkeleychat_UploadAudioResponse {
        // TODO: let accessToken = request.accessToken
        let audio = request.audio

        let audioURL = try await s3.upload(data: audio, fileExtension: "mp3")
        print("audioURL", audioURL)
        return Berkeleychat_UploadAudioResponse.with {
            $0.audioURL = audioURL
        }
    }

    func createAccount(request: Berkeleychat_CreateAccountRequest, context _: GRPCAsyncServerCallContext) async throws -> Berkeleychat_CreateAccountResponse {
        do {
            let email = request.email
            let name = request.name
            let profilePhotoURL = request.profilePhotoURL
            let major = request.major
            let courses = request.courses
            let introURL = request.introURL
            print("profilePhotoURL", profilePhotoURL)
            print("introURL", introURL)
            async let asyncInitializeUser = redis.hmset([
                "email": email,
                "name": name,
                "profilePhotoURL": profilePhotoURL,
                "major": major,
                "coursesString": courses.joined(separator: "|"),
                "introURL": introURL,
            ], in: "user.profile:\(email)").get()
            // makeSymmetric

            async let asyncAddToMajor = redis.sadd(email, to: "major.emails:\(major)").get()

            async let asyncCourseOverlap = withThrowingTaskGroup(of: Void.self) { group in
                let emailToQuantityOverlap = EmailToNumberMap()

                for course in courses {
                    group.addTask { [self] in
                        async let asyncAddToCourse = redis.sadd(email, to: "course.emails:\(course)").get()
                        async let asyncCourseEmails = redis.smembers(of: "course.emails:\(course)").get()

                        _ = try await asyncAddToCourse

                        let courseEmails = try await asyncCourseEmails

                        for email in courseEmails {
                            _ = await emailToQuantityOverlap.increment(email: email.string!)
                        }
                    }
                }

                for otherEmail in await emailToQuantityOverlap.map.keys where otherEmail != email {
                    group.addTask { [self] in
                        _ = try await [redis.zadd(
                            (element: otherEmail, score: Double(await emailToQuantityOverlap.map[otherEmail]!)), to: "user.course.overlap:\(email)"
                        ).get(), redis.zadd(
                            (element: email, score: Double(await emailToQuantityOverlap.map[otherEmail]!)), to: "user.course.overlap:\(otherEmail)"
                        ).get()]
                    }
                }
            }

            async let asyncIntroSimilarity = withThrowingTaskGroup(of: Void.self) { _ in

                let intro = try await s3.download(fileURL: introURL)

                let transcription = try await transcribeAudio(audioData: intro, httpClient: httpClient)
                print("transcription", transcription)
                let embedding = try await getEmbedding(text: transcription, httpClient: httpClient)

                let dataData = embedding.withUnsafeBufferPointer {
                    Data(buffer: $0)
                }

                try await redis.set("user.intro.embedding:\(email)", to: dataData).get()

                let otherUserEmbeddingKeys = try (await redis.scan(startingFrom: 0, matching: "user.intro.embedding:*", count: 100).get()).1

                for otherUserEmbeddingKey in otherUserEmbeddingKeys {
                    let otherUserEmbeddingData = try await redis.get(RedisKey(otherUserEmbeddingKey)).get()

                    let otherUserEmbedding = otherUserEmbeddingData.data!.withUnsafeBytes { otherUserEmbedding in
                        Array(otherUserEmbedding.bindMemory(to: Float.self))
                    }

                    let dotProduct = dotProduct(embedding, otherUserEmbedding)

                    let otherUserEmail = String(otherUserEmbeddingKey.split(separator: ":").last!)

                    _ = try await [redis.zadd(
                        (element: otherUserEmail, score: dotProduct), to: "user.intro.similarity:\(email)"
                    ).get(), redis.zadd(
                        (element: email, score: dotProduct), to: "user.intro.similarity:\(otherUserEmail)"
                    ).get()]
                }
            }

            // await all asyncs
            try await asyncInitializeUser
            _ = try await asyncAddToMajor
            await asyncCourseOverlap
            try await asyncIntroSimilarity

            return Berkeleychat_CreateAccountResponse()
        } catch {
            print(error)
            return Berkeleychat_CreateAccountResponse()
        }
    }

    func getUsers(request: Berkeleychat_GetUsersRequest, context _: GRPCAsyncServerCallContext) async throws -> Berkeleychat_GetUsersResponse {
        async let asyncEmailsOfMajor = redis.smembers(of: "major.emails:\(request.major)").get()
        async let asyncEmailsOfCourseOverlap = redis.zrange(from: "user.course.overlap:\(request.email)", upToIndex: 100, includeScoresInResponse: true).get()
        async let asyncEmailsOfIntroSimilarity = redis.zrange(from: "user.intro.similarity:\(request.email)", upToIndex: 100, includeScoresInResponse: true).get()
        let emailsOfMajorRaw = try await asyncEmailsOfMajor
        let emailsOfCourseOverlapRaw = try await asyncEmailsOfCourseOverlap
        let emailsOfIntroSimilarityRaw = try await asyncEmailsOfIntroSimilarity
        let emailsOfMajor = emailsOfMajorRaw.map {
            $0.string!
        }
        let emailsOfCourseOverlap = stride(from: 0, to: emailsOfCourseOverlapRaw.count, by: 2).map {
            (email: emailsOfCourseOverlapRaw[$0].string!, score: emailsOfCourseOverlapRaw[$0 + 1].int!)
        }
        let emailsOfIntroSimilarity = stride(from: 0, to: emailsOfIntroSimilarityRaw.count, by: 2).map {
            (email: emailsOfIntroSimilarityRaw[$0].string!, score: Double(emailsOfIntroSimilarityRaw[$0 + 1].string!)!)
        }
        var emailToOverallScoreMap = [String: Int]()
        for email in emailsOfMajor {
            emailToOverallScoreMap[email] = 5
        }
        for (email, quantityOverlap) in emailsOfCourseOverlap {
            let increment = NSDecimalNumber(decimal: pow(Decimal(quantityOverlap), 3)).intValue
            if let score = emailToOverallScoreMap[email] {
                emailToOverallScoreMap[email] = score + increment
            } else {
                emailToOverallScoreMap[email] = increment
            }
        }
        for (email, score) in emailsOfIntroSimilarity {
            print(email, score)
            let increment = NSDecimalNumber(decimal: pow(Decimal(score * 10), 3)).intValue
            if let score = emailToOverallScoreMap[email] {
                emailToOverallScoreMap[email] = score + increment
            } else {
                emailToOverallScoreMap[email] = increment
            }
        }

        emailToOverallScoreMap[emailsOfIntroSimilarityRaw.first!.string!] = 1

        var profilesWithScores = [(email: String, name: String, major: String, courses: [String], introURL: String, profilePhotoURL: String, messages: [String], score: Int)]()

        try await withThrowingTaskGroup(of: (String, [String: RESPValue], [String], Int).self) { group in
            for (email, score) in emailToOverallScoreMap {
                group.addTask { [self] in
                    async let asyncValues = redis.hgetall(from: "user.profile:\(email)").get()
                    async let asyncMessages = redis.smembers(of: "user.messages:\(email)").get()

                    let values = try await asyncValues
                    let messages = try await asyncMessages.compactMap { $0.string }

                    return (email, values, messages, score)
                }
            }

            for try await (email, values, messages, score) in group {
                let name = values["name"]?.string ?? ""
                let major = values["major"]?.string ?? ""
                let courses = values["courses"]?.string?.components(separatedBy: ",") ?? []
                let introURL = values["introURL"]?.string ?? ""
                let profilePhotoURL = values["profilePhotoURL"]?.string ?? ""

                profilesWithScores.append((email: email, name: name, major: major, courses: courses, introURL: introURL, profilePhotoURL: profilePhotoURL, messages: messages, score: score))
            }
        }

        // Sort profiles by score in descending order
        profilesWithScores.sort { $0.score > $1.score }

        print(profilesWithScores)

        // Create the response using the `with` method
        let response = Berkeleychat_GetUsersResponse.with {
            $0.users = profilesWithScores.map { profile in
                Berkeleychat_User.with {
                    $0.email = profile.email
                    $0.name = profile.name
                    $0.major = profile.major
                    $0.courses = profile.courses
                    $0.introURL = profile.introURL
                    $0.profilePhotoURL = profile.profilePhotoURL
                    $0.messages = profile.messages
                }
            }
        }

        return response
    }

    func getMessages(request: Berkeleychat_GetMessagesRequest, responseStream: GRPCAsyncResponseStreamWriter<Berkeleychat_Message>, context _: GRPCAsyncServerCallContext) async throws {
        let email = request.email

        _ = redis.subscribe(to: ["pubsub:\(email)"]) { _, message in
            let fromEmail = String(message.string!.split(separator: ":").first!)

            let content = message.string!.split(separator: ":").dropFirst().joined(separator: ":")

            Task {
                try await responseStream.send(Berkeleychat_Message.with {
                    $0.toEmail = email
                    $0.fromEmail = fromEmail
                    $0.content = content
                }
                )
            }
        }
    }

    func sendMessage(request: Berkeleychat_Message, context _: GRPCAsyncServerCallContext) async throws -> Berkeleychat_Message {
        let toEmail = request.toEmail
        let fromEmail = request.fromEmail
        let content = request.content

        _ = try await redis.publish("\(fromEmail):\(content)", to: "pubsub:\(toEmail)").get()

        Task {
            try await redis.lpush(content, into: "user.messages:\(fromEmail)").get()
        }

        return Berkeleychat_Message.with {
            $0.toEmail = toEmail
            $0.fromEmail = fromEmail
            $0.content = content
        }
    }
}
