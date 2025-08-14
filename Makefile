CC = gcc
CFLAGS = -O2 -fPIC -shared -m64 -Wl,-rpath,'$ORIGIN/./lib/lua'
LUA_DIR = ./include/lua/include
LUA_LIB = ./lib/lua
LUA_CFLAGS = -I$(LUA_DIR)
LUA_LIBS = -L./lib/lua -llua-5.4

all: liblpb.so

liblpb.so: pb.o
	$(CC) pb.o -o liblpb.so $(CFLAGS) $(LUA_LIBS)

pb.o:
	$(CC) -c pb.c $(CFLAGS) $(LUA_CFLAGS)

clean:
	rm -f *.o *.so