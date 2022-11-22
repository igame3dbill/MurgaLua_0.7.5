# Create shared library's object file
gcc -c -DBUILD_DLL alientest.c

# Create shared library.
gcc -shared -o alientest.dll alientest.o

# Clean up
rm alientest.o
