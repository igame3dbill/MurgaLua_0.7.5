V=1.0

CFLAGS=-O2 -Wall -I/home/nop/lua-5.0/include -fPIC -g

DYN=libluaiostring.so.$(V)
STA=libluaiostring.a

OBJS=iostring.o

dyn: $(DYN)
sta: $(STA)

$(STA): $(OBJS)
	ar rcu $(STA) $(OBJS)
	ranlib $(STA)

$(DYN): $(OBJS) 
	$(CC) -shared -o $(DYN) $(OBJS)

clean:
	rm -f $(STA) $(DYN) $(OBJS)
