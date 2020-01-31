It may be tempting to use a fancy disk cloning tool such as Clonezilla, but do yourself a favor and don't.  I ended up using Clonezilla without doing much research first, and it was a real pain to get any data restored.

Clonezilla does not support mounting images in order to restore individual files.  Various docs mention that it is possible through a hack, and while that's true, it is very painful.  You are better off choosing a manual option that is more easily mounted.

If you find yourself in the unfortunate position of having a Clonezilla backup that you want to restore files from, here's some background information and some options.

Clonezilla uses various backends to do the actual cloning.  A popular one that was used when I did my backup is called partclone.  It works by writing an image in a special format that stores only data that is relevant to the underlying file system.  In other words, it skips free space.  This is a good thing in that the image will take up less space.  However, there is no way to mount an image in this format in order to read files from it.  The only option is to expand it into raw format either to a disk partition or a raw image file.  This requires enough free space to cover the entire full size of the disk partition that the image came from.  Not only that, but depending on the size of the image, it may very well take hours to perform this conversion.  Further complicating things, another popular option is to gzip the entire image to further compress the stored size.  Even if the image were raw, gzipping would prevent it from being able to be mounted.  It also complicates the restore process possibly adding further processing time.

Here's how to get a raw mountable image file from a gzipped partclone image of an ext4 file system:

1. Follow online directions for doing so.
    - TODO: Document the steps I took.
2. When you try mounting the image, you may get a vague error message such as `wrong fs type, bad option, bad superblock on /dev/loop0, missing codepage or helper program, or other error`.  In my case, this was because the image file was smaller than the ext4 file system.  I assume this is because the end of the partition may not contain any meaningful data, so partclone skipped it.  You can fix it by expanding the size of the image file.
    1. Use `dmesg` to find out more information about the error.  In my case, it said `EXT4-fs (loop0): bad geometry: block count 223147597 exceeds size of device (222827540 blocks)`.  Assuming yours is the same issue, let's continue with expanding the image file.
    2. Calculate the block size.  The "device" is the image file.  Take the actual size of the file and divide it by the number of blocks reported that the "device" has.  You should end up with an integer, most likely a power of 2 such as `4096`.
    3. Multiply the block size by what the block count should be in order to get the needed size in bytes.
    4. Use `truncate` to change the file size.
        - CAUTION: You can lose data if you accidentally specify the wrong size.
        - `truncate --size=914012557312 /path/to/image.img`, for example.

If not Clonezilla or partclone, what should you use?  I would recommend `ddrescue`.  First of all, `dd` is a handy little tool that generally comes with Linux that shovels data around.  You can use it, for example, to copy the raw data from a disk or disk partition and shove it in a file.  That file is a raw image that can be mounted.  It will take up exactly the same amount of space as the disk or disk partition it was taken from, because it's just a raw copy.  In fact, it even copies free space, so deleted files can even be recovered from the resulting image.  `ddrescue` is a variation of `dd` that adds some error checking.

But that's a lot of space, especially if a good chunk of your disk or partition is free space.  What can be done about this?  I recommend shrinking the partition to reduce the free space.  You can do this ahead of time before doing the backup which may make sense if you plan to destroy the original partition.  Or, you can create a loop device that points to the raw image after the fact and use file system tools to shrink the file system stored in the image file, then truncate the file.  After all that, if you really want to, you can manually gzip the image, or use whatever compression tool you prefer, to try to reduce it further.  Just keep in mind that you will have to decompress it before mounting it.

TODO: Cover specific instructions for the above.
