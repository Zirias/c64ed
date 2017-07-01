#include <stdio.h>
#include <inttypes.h>

#define BUFSIZE 64*1024

unsigned char buf[BUFSIZE];

int main()
{
    unsigned char addrbytes[2];
    uint16_t startaddress;

    if (fread(addrbytes, 1, 2, stdin)!=2)
    {
        fputs("Error reading start address\n", stderr);
        return 1;
    }
    startaddress = addrbytes[1] << 8 | addrbytes[0];

    size_t nread = fread(buf, 1, BUFSIZE, stdin);
    if (!nread)
    {
        fputs("Error: couldn't read any data\n", stderr);
        return 1;
    }
    uint16_t endaddress = startaddress + (uint16_t)nread - 1;

    printf("0fOa=%" PRIu16 "to%" PRIu16 ":rEb:pOa,b:nE:sY%" PRIu16,
            startaddress, endaddress, startaddress);

    int lineno = 0;
    int remaining = 0;
    unsigned char *r = buf;
    while (nread--)
    {
        int needed=2;
        if (*r>9)++needed;
        if (*r>99)++needed;
        if (remaining - needed < 0)
        {
            ++lineno;
            remaining = 77-needed;
            if (lineno>9) --remaining;
            if (lineno>99) --remaining;
            if (lineno>999) --remaining;
            if (lineno>9999) --remaining;
            printf("\n%ddA%u", lineno, (unsigned)*r++);
        }
        else
        {
            remaining -= needed;
            printf(",%u", (unsigned)*r++);
        }
    }
    putchar('\n');

    return 0;
}
