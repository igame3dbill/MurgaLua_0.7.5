# Create shared library's object file
gcc -fPIC -Wall -g -c alientest.c

# Create shared library.
# Use -lc to link it against C library
gcc -g -shared -Wl,-soname,alientest.so.0 \
    -o alientest.so alientest.o

# Clean up
rm alientest.o
