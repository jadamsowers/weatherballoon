#include <fcntl.h> 
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <termios.h> 
#include <sys/time.h>
#include <sys/stat.h> 
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>

/* baudrate settings are defined in <asm/termbits.h>, which is included by <termios.h> */ 

int makeSocket(int port)
{
    int    sockfd,sd,childpid;
    struct sockaddr_in serv_addr;
           
    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        fprintf(stderr,"Server Error:  Can't open stream socket.\n");
        return -1;
    }
        
    bzero((char*) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family        =AF_INET;
    serv_addr.sin_addr.s_addr   =htonl(INADDR_ANY);
    serv_addr.sin_port          =htons(port);
    
    if (bind(sockfd, (struct sockaddr*) &serv_addr, sizeof(serv_addr))<0)
    {
        fprintf(stderr,"Server Error:  Can't bind to local address.\n");
        return -1;
    }

    listen(sockfd,5);
    return sockfd;
}
int makeSerialPortSocket(char port[],int baud)
{
        int fd; 
        struct termios newtio; 

        fd = open(port,O_RDWR); // open up the port on read / write mode
        if (fd == -1)
                return(-1); // Opps. We just has an error

        /* Save the current serial port settings */
        tcgetattr(fd, &newtio);
        
        /* Set the input/output baud rates for this device */
        cfsetispeed(&newtio, baud); //115200

        /* CLOCAL:      Local connection (no modem control) */
        /* CREAD:       Enable the receiver */
        newtio.c_cflag |= (CLOCAL | CREAD);

        /* PARENB:      Use NO parity */
        /* CSTOPB:      Use 1 stop bit */
        /* CSIZE:       Next two constants: */
        /* CS8:         Use 8 data bits */
        newtio.c_cflag &= ~PARENB;
        newtio.c_cflag &= ~CSTOPB;
        newtio.c_cflag &= ~CSIZE;
        newtio.c_cflag |= CS8;

        /* Disable hardware flow control */
        // BAD:  newtio.c_cflag &= ~(CRTSCTS);

        /* ICANON:      Disable Canonical mode */
        /* ECHO:        Disable echoing of input characters */
        /* ECHOE:       Echo erase characters as BS-SP-BS */
        /* ISIG:        Disable status signals */
        // BAD: newtio.c_lflag = (ECHOK);

        /* IGNPAR:      Ignore bytes with parity errors */
        /* ICRNL:       Map CR to NL (otherwise a CR input on the other computer will not terminate input) */
        // BAD:  newtio.c_iflag |= (IGNPAR | ICRNL);
        newtio.c_iflag |= (IGNPAR | IGNBRK); 
        
        /* NO FLAGS AT ALL FOR OUTPUT CONTROL  -- Sean */
        newtio.c_oflag = 0;

        /* IXON:        Disable software flow control (incoming) */
        /* IXOFF:       Disable software flow control (outgoing) */
        /* IXANY:       Disable software flow control (any character can start flow control */
        newtio.c_iflag &= ~(IXON | IXOFF | IXANY);

        /* NO FLAGS AT ALL FOR LFLAGS  -- Sean*/
        newtio.c_lflag = 0;

        /*** The following settings are deprecated and we are no longer using them (~Peter) ****/
        // cam_data.newtio.c_lflag &= ~(ICANON && ECHO && ECHOE && ISIG); 
        // cam_data.newtio.c_lflag = (ECHO);
        // cam_data.newtio.c_iflag = (IXON | IXOFF);
        /* Raw output */
        // cam_data.newtio.c_oflag &= ~OPOST;

        /* Clean the modem line and activate new port settings */
        tcflush(fd, TCIOFLUSH);
        tcsetattr(fd, TCSANOW, &newtio);

        return(fd);
}

int waitOnSocket(int sockfd)
{
    struct sockaddr_in  cli_addr;
    int clilen = sizeof(cli_addr);
    int sd;

    sd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
    
    if (sd <0)
    {
        fprintf(stderr,"Server Error:  Accept error.\n");
        return -1;
    }

    return sd;    
}

int max(int a, int b)
{
    return (a > b ? a : b);
}

#define BUFFER 1024
int main(int argc, char *argv[])
{
    fd_set rset;
    struct timeval timeout;
    char c[BUFFER];
    int csize;

    int sd1;
    int sd2;
    int sockfd1, sockfd2;
    int mode;
    int x;
    int args = 0;
    int tmp;

    char argSerial[] = "-serial";
    char argPort[]   = "-port";
    char argStrip[]  = "-strip";
    char argBaud[]   = "-baud";
    char argDebug[]  = "-debug";

    int SOCKET_PORT, BAUD, STRIP, DEBUG = 0;
    char SERIAL[100];

    printf("Parsing startup data.....\n");

    for (x = 0; x < argc; x++) {
	if (!strcmp(argSerial,argv[x])) {
		strcpy(SERIAL,argv[x+1]);
		args++;
	}
	else if (!strcmp(argPort,argv[x])) {
		SOCKET_PORT = atoi(argv[x+1]);
		args++;
	}
	else if (!strcmp(argBaud,argv[x])) {
		tmp        = atoi(argv[x+1]);
		switch (tmp) {
			case 115200:
				BAUD = B115200;
				break;
			case 38400:
				BAUD = B38400;
				break;
			case 19200:
				BAUD = B19200;
				break;
			case 9600:
				BAUD = B9600;
				break;
			default:
				printf("ERROR!: Unknown baud rate.\n");
				return 1;
				break;
		}
		args++;
	}
	else if (!strcmp(argStrip,argv[x]))
		STRIP = 1;
	else if (!strcmp(argDebug,argv[x]))
		DEBUG = 1;
    }

    if (args < 3) {
	    printf("--------------------------------------\n");
	    printf("----------  GMU SerialDaemon ---------\n");
	    printf("--------------------------------------\n");
	    printf("Usage:\n");
	    printf("\tserialdaemon\n");
	    printf("\t\t-serial [serialPort]\n");
	    printf("\t\t-port   [TCP/IP Port]\n");
	    printf("\t\t-baud   [baudRate]\n");
	    printf("\t\t\t115200\n");
	    printf("\t\t\t38400\n");
	    printf("\t\t\t19200\n");
	    printf("\t\t\t9600\n");
	    printf("\t\t?-strip?\n\n");
	    printf("\t\t?-debug?\n\n");
	    return(1);
    }

    if (DEBUG)
	    printf ("DEBUG: debug mode on!\n");

    sockfd1 = makeSocket(SOCKET_PORT);
    if (sockfd1 <= 0) { printf("ERROR: couldn't make TCP/IP socket!\n"); close(sockfd1); return; }
    sockfd2 = makeSerialPortSocket(SERIAL, BAUD);
    if (sockfd2 <= 0) { printf("ERROR: couldn't open serial port!\n"); close(sockfd1); close(sockfd2); return; }

    if (argc <= 1)
	    mode = 0;
    else
	    mode = atoi(argv[1]);

    printf("\tDone!\nListening for connections on port: %i\n",SOCKET_PORT);

    while(1)
    {
        sd1 = waitOnSocket(sockfd1);
	    if (DEBUG)
		    printf("DEBUG: New client socket opened.\n");
        if (sd1 < 0) {
               close(sd1); 
               return;
        }
        sd2 = sockfd2;
        if (sd2 < 0) {
              close(sd1);
              close(sd2); 
              return;
        }
        FD_ZERO(&rset);
    
        /* Select on sockets */
    
        while(1)
        {
            FD_SET(sd1,&rset);
            FD_SET(sd2,&rset);

            select(max(sd1,sd2)+1,&rset,NULL,NULL,NULL);
            if (FD_ISSET(sd1,&rset))
	    {  /* There's stuff to read */
                if ((csize= read(sd1, c, BUFFER)) >= 1)
		{
		    if (STRIP==1)
		    {
		      for(x = 0 ; x < csize; x++)
		      {
			   if (c[x] == '\n' )
			   {
			   	 c[x] = ' ';
				 if (DEBUG)
					 printf ("DEBUG: **STRIPPED**\n");
			   }	
		      }

		    }
		    if (DEBUG) {
			    c[csize] = '\0';
			    printf("DEBUG: sd2 ==> %s\n",c);
		    }
		    write(sd2, c, csize);
		}
                else break;           /* Failed */
	    }
            if (FD_ISSET(sd2,&rset)) {
                if ((csize = read(sd2, c, 1)) >= 1) {
                    write(sd1, c, csize);
		    if (DEBUG) {
			    c[csize] = '\0';
			    printf("DEBUG: sd1 <== %s\n",c);
		    }
		}
                else break;           /* Failed */
	    }
        }

        printf("Restarting\n");
        close(sd1);/* clean up */
   }
}
