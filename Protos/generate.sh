#!/bin/zsh
rootabspath=$(cd "$(dirname "$0")" && cd .. && pwd)
protoc --grpc-swift_opt=Client=true,Server=true --grpc-swift_out=${rootabspath}/Server/Sources/GRPCGenerated --swift_out=${rootabspath}/Server/Sources/GRPCGenerated --proto_path "${rootabspath}"/Protos ${rootabspath}/Protos/*.proto
protoc --grpc-swift_opt=Client=true,Server=false --grpc-swift_out=${rootabspath}/Client/Berkeleychat/GRPCGenerated --swift_out=${rootabspath}/Client/Berkeleychat/GRPCGenerated --proto_path "${rootabspath}"/Protos ${rootabspath}/Protos/*.proto
