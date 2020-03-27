
# TemporalLib (codename SteveLib)

TemporalLib can generate random numbers, using time() instruction. (`rtdsc`?) 

Time() is interesting, its a physical sensor, like microphone, that can get physical entropy.

This is research to play around with! Don't expect anything more! Have fun experimenting or don't use.

![Temporal Randomness](screenshot.png)

This project was inspired by the fatum project, a totally cool project about: Novelty, deeper mystery, and expanded exploration. Give it a look. http://randonauts.com    


# compile

	./make.sh
		(or)	
	./make.sh noinstall
		(or)	
	./make.sh android # cross-compile for android on a Mac/PC. Needs android NDK.


# Efforts made

* The design of the code is important. We need to "defeat optimisations". For example my time-generator doesn't just call `Time32`, it ALSO xor's the result and returns it, ensuring it isn't optimised away.
* We use warmups to help timings.
* We try various mod sizes to extract randomness. (like `temporal_rand() mod 17`)
* Uses histograms, von-neuman and XOR.
* We use some defines to make code more consistant. `Time_`, `for_`, `Gen`
* A lot more design is going on, inside... to make it work and be nice...

![Temporal Randomness](screenshot2.jpg)



# Use

Compiling should build a lib, and a shell-tool.

The shell-tool can dump randomness into a file, or just test various approaches and graphically display them in an HTML file (like the pics above!)

to dump randomness:

	temporal dump    ChannelNum FileSize File.txt
	temporal hexdump ChannelNum FileSize File.txt # to get hex instead of a binary
	temporal list    ChannelNum
		
example:

	temporal dump        1      128KB    File.txt
	temporal list        1
	temporal hexdump     0      128MB    File.txt # dump chaotic generators
	temporal list        0                        # view chaotic generators



# Channels

What are "channels"? Well, I wanted my lib to be like watching TV, so you flip between TV-channels, trying to find the best signal. Channels range from 0 to 127.

Channel 0 is used for my chaotic-generator. They are so good they don't need much debiasing, just XOR/Neuman.

Channel 1 upwards use non-chaotic-generators, but then hash them, otherwise the randomness isn't good enough. This also makes them much faster, as XOR/Neuman lose a lot of bits.

So basically, Channel 1 is faster and more random, but might have less intention-driven results.

Channel 0 is slower and less random (but still extremely random!), but may have stronger intention-driven results.



# theory

The aim is to see if we can get a computer to "Feel" things, or even just feel itself.

We need to step outside determinism. We need the computer to physically interact with itself. And sense emotions/energy. You might say "well physically sensing something doesn't give you that". But actually all physical objects even rocks or metal can sense emotions or energy, or nothing can.

Some physical objects are better at sensing emotions/energy, just like some physical objects are better for building a house out of, but no one is stopping you from building a cardboard house! And to be able to sense emotions AT ALL is better than nothing.

Thats the goal anyhow.

