## Welcome to the PsychoHTTP project. A attempt to make a full stack http website in 32-bit AT&T Assembly.

I started writing this server around May 2026 more just as a small project trying to just to see how syscalls work.
Nothing more than just that. This later scaled up to become a full on a high effort joke attempt at making a HTTP server in Assembly.
I thought making this would be productive because making such a thing in 32-bit Assembly would be a great accomplishment. And i would learn allot from it.
Eventually as of today when i am writing this (1-Oct-2026) Its oficially done!
I am very proud of this. And i hope you'll be impressed by this.
Cause after the dedication of making this: I truly think the name PsychoHTTP fits this project very well. Feel free to attempt to run this on your own machine!

### How do i run this?
Running this should be easy to do. But if its not, feel free report a potential bug you're experiancing. I am not one of those Inconsiderate programmers that gets mad at you for this because **Uhhhh, iT wOrKs oN mY mAsChInE.** If you do give me a bug report though: Please give me as much information of the bug itself and the enviorenment you're running. So i can replicate it myself and eventually fix it. Even vague Instructions in the README or comments or word typo's anywhere count as bugs.

##### Step 1: Check if you have the required software.
Please check if you have the required software insalled to run this in the first place. To check if you have the right requirements; please type these commands in to check:
###### Check if you are on the correct Fedora version
You need a program called Fastfetch, if you do not installed yet. Install it:

```$ sudo dnf install fastfech```

If you have fastfetch, simply type in the command and see the version on the OS label. Like for me it says: `(Fedora Linux 44 (KDE Plasma Desktop Edition) x86_64)`

```$ fastfetch```

###### Check if you have correct version gcc and python installed
You have check if you have the correct version of gcc installed you type in:

```$ gcc --version```

```$ python3 --version```

##### Step 2: Compile the server itself:
To compile the server code itself you must be in the /build directory. 
After this, you van run this command:

```$ Python3 ./build_system.py```

If there is an error you should see a message in the CLI logged.
If there is a syntax error, it'll log this inside a log.txt file.
If a log.txt file is generated it'll notify you trough the CLI.

##### Step 3: Run the server
To run the server you go back to the root directory of thei project and then go the /out directory.
After that you simply type in:

```$ ./server.out```

And the server will start running.
For extra log info and if you have `strace` installed. You can type in:

```$ strace ./server.out```

### Requirements:
- Fedora Linux 44
- GCC 16.2.1
- Python 3.14.7

### FAQ:
> Are you really planning to update and add more features to this server?
- **YES, 100% sure i will eventually.** But for now, i might stay away from most updates because i am just burnt out from working on it for so long :D.

####

> Why did you write this in 32-bit mode instead of 64-bit mode?
- Because i wanted to challange myself. 64-bit mode has more registers and documentation. Doing it with less would be an interesting challange.

####

> Why did you pick python as your build system?
- CMake and Makefile was being a pain to deal with for reason i wont get into.

####

> Whats the benefit of making such a server in Assembly?
- Purely educational + Something i can show off to others for fun!

####

> What if this server doesnt run on my machine?
- You are always allowed to report such bug reports in this repo!
