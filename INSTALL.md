# Installing Progyon

## Checkout

After cloning the repository, check out the submodules:

```
git submodule update --init
```

## Dependencies

Make sure to gather all the dependencies: libusb-1.0, and libudev if you're using Linux.

## Build

Run the following command:

```
make
```

Afterwards, the file `progyon` will appear in the build directory.

## Up to date info

When in doubt whether this file has been updated, make sure to check the `.gitlab-ci.yml` file. Problems in that one will alert the maintainers.
