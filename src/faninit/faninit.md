# **faninit**

This is a replacement for `/sbin/init` that launches directly into the Fantom
runtime on start-up. It is intentionally minimalist as it expects Fantom to be
in charge of application initialization and supervision.

Based on **erlinit** by Frank Hunleth:

[https://github.com/nerves-project/erlinit](https://github.com/nerves-project/erlinit)