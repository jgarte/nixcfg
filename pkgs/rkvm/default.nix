{ stdenv, rustPlatform, fetchFromGitHub
, pkg-config, libevdev, openssl, llvmPackages_latest, linuxHeaders }:

let
  metadata = import ./metadata.nix;
in
rustPlatform.buildRustPackage rec {
  pname = "rkvm";
  version = metadata.rev;

  src = fetchFromGitHub {
    owner = "htrefil";
    repo = pname;
    rev = metadata.rev;
    sha256 = metadata.sha256;
  };

  cargoSha256 = metadata.cargoSha256;

  postPatch = ''
    sed -i 's|.clang_arg("-I/usr/include/libevdev-1.0/")|.clang_arg("-I${libevdev}/include/libevdev-1.0").clang_arg("-I${linuxHeaders}/include")|g' ./input/build.rs
  '';

  nativeBuildInputs = [ pkg-config openssl llvmPackages_latest.libclang ];
  LIBCLANG_PATH = "${llvmPackages_latest.libclang}/lib";
  buildInputs = [ libevdev openssl linuxHeaders ];

  meta = with stdenv.lib; {
    description = "Virtual KVM switch for Linux machines";
    homepage = "https://github.com/htrefil/rkvm";
    license = licenses.mit;
    maintainers = [ maintainers.colemickens ];
  };
}
