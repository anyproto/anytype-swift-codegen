# Build release script.

# Suppose, that script is here -> /root/Scripts/script.sh
# $0 -> Script path. (./script.sh ) # relative path to a directory from where you call it.
# realpath $0 -> Absolute path to script ( from root ), /root/Scripts/script.sh
# dirname $(realpath $0) - Absolute path to Script folder. ( /root/Scripts )
# dirname $(dirname $(realpath $0)) - Absolute path to Script parent folder. ( /root/ )
cd $(dirname $(dirname $(realpath $0)))

echo "Traveling to directory $(pwd)"

# Build main tool
echo "Start build main tool anytype-swift-codegen"
swift build -c release

# Build dependent tool
echo "Start build dependent tool swift-format"
swift build --product swift-format -c release

mkdir release || true

# Gather binaries
echo "Gathering tools in ./release"
cp ./.build/release/anytype-swift-codegen ./release
cp ./.build/release/swift-format ./release
