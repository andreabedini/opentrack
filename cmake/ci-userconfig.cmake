# Deliberately empty.
#
# opentrack-load-user-settings.cmake otherwise picks a file by
# "$USER@$COMPILER-$TARGET". On GitHub's runners that resolves to the
# sdk-paths-runner@... / sdk-paths-runneradmin@... files in the repository root,
# which describe upstream's CI: they expect an opentrack-depends checkout and a
# prebuilt OpenCV under $GITHUB_WORKSPACE/artifacts, and they override the
# optimisation flags. sdk-paths-runner@AppleClang-Darwin.cmake in particular
# calls find_package(OpenCV REQUIRED) against a path this workflow never
# populates, which fails the configure outright.
#
# The vcpkg-based build gets its dependencies from vcpkg.json and the
# distribution instead, so point OPENTRACK_USERCONFIG here to opt out of all of
# it without disturbing the files upstream's own CI relies on.
