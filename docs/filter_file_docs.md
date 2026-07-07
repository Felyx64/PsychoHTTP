# how does the filter file work?

The filter.txt file contains info about what info belonging to a request we should block.
The file is very basic. The filter is devided into catagories which each block another certain aspect.
There are no labels specifying which is an ip or user-agent since both are structured so differently
+ The file can add blocker too (along with their labels):
- User Agents
- IPs

### The folder should be exactly like this
```
known-annoying-web-bot
another-annoying-scraper
Window7-internet-explorer
256.100.50.25
192.168.1.1.1
192.168.0x0.1
192.168..1
192.168.001.1
```
