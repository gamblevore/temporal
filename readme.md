
# about

The idea is to generate random numbers, using the CPU's time() instruction, usually `rtdsc` on intel.

Time information is really important and interesting, because it is a physical sensor, like a camera-pixel or a microphone. We can try get randomness from this sensor. However, it's an **internal** physical sensor, which we hope we can do extra cool things with.

This is research to play around with! Don't expect anything more than that! Have fun experimenting or don't bother opening.

It should generate some randomness pictures in a `time_img` folder in your current directory. Quite interesting and fun pictures!

![Temporal Randomness](screenshot.png)

This project was inspired by the fatum project, a totally cool project about: Novelty, deeper mystery, and expanded exploration. Give it a look. http://randonauts.com    


# compile

compile: `g++ -pthread -std=c++0x -Os temporal.cpp -o temporal`
or use the Xcode project supplied


# Efforts made

* The design of the code is important. We need to "defeat optimisations". For example my time-generator doesn't just call `Time32`, it ALSO xor's the result and returns it, ensuring it isn't optimised away.
* Also, our time is 32-bit, 4GB time-deltas is plenty!
* We use warmups to help timings.
* We try various mod sizes to extract randomness. (like `temporal_rand() mod 17`)
* We use some defines to make code more consistant. `Time_`, `for_`, `Gen`
* Detects and rejects time-spikes caused by interupts, contention, etc.
    

# Please experiment:

Improve / replace any code in here... for example:

    Time_ (Reps) {
        y = y + 1000.5;
        x = x / 2.0;
        x = fmodf(x,2.0) - (x / 10000000.0);
        x = floor(x)     - (x * 5000000.0);
        x = fminf(x, MAXFLOAT);
        y = fmaxf(y,-MAXFLOAT);
        x += y;
    } TimeEnd

* Do we need so many instructions? Do we need all? Some? Who knows! I don't! haha.
* What about altering Reps? That affects things a lot! Are more reps good or less? Or certain numbers (primes?) of samples?
* Modern CPUs try to reduce time randomness. For us its undesirable! Perhaps rarer CPUs have more random timings? Could be interesting!
* It would be a cool idea to make the randomness generated be animated, perhaps using SDL2.


# theory

The aim is to do research to see if we can get a computer to "Feel" things, or even just feel itself.

We need to step outside determinism, via physical sensors. Just sensing the outside world isn't enough if the internal space (CPU/RAM) is deterministic. We need the computer to physically interact with itself.

We actually want to go beyond that into sensing emotions/energy. You might say "well physically sensing something doesn't give you that". But actually all physical objects even rocks or metal can sense emotions or energy, or nothing can.

Some physical objects are better at sensing emotions/energy, just like some physical objects are better for building a house out of, but no one is stopping you from building a cardboard house! And to be able to sense emotions AT ALL is better than nothing.

Thats the goal anyhow.

