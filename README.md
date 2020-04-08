# xftts-cli

A simple CLI for generating mp3 based on Xun Fei TTS. Usage:

```bash
xftts-cli test/1-dart.md test/dart.mp3
```

Make sure you have these environment variable defined:

```
XF_TTS_ID1
XF_TTS_KEY1
XF_TTS_SECRET1
XF_TTS_VCN
```

Have a feel of the generated mp3 (note this is using vcn as 'x2_xiaoyuan'):

![dart：失之东隅收之桑榆](test/dart.mp3)

If you don't want to setup your own dart environment, you could use the generated release on release page. Right now only OSX is supported.
