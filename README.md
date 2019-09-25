# static-site-toolkit

### Description 

Tools to streamline the publishing of static web content.

### Goals

1. Minimize external dependencies. 
1. Leverage available tools to the greatest extent possible: sed, awk, grep, Make, shell
1. Don't use python. Too slow for my taste.
1. Transcend the limitations of the simpler tools such as [saait](https://git.codemadness.org/saait), [sw](https://github.com/jroimartin/sw), [ssg5](https://www.romanzolotarev.com/ssg.html) (from which this is partially derived from), and yet avoid the complexity of [Pelican](https://github.com/getpelican).

### Features

- Develop plain html or markdown content. Uses [lowdown](https://kristaps.bsd.lv/lowdown/) to compile the markdown.
- Leverage the markdown metadata to populate your pages, with or without the *yaml* surrounding delimiters.
- Global header and footer templates for all content.
- Generate *indexed* content from special header/footer/body templates, respecting the above *global* header and footer. The index templates, similarly, support site and metadata originating variables. (Inspired by *saait*.) Examples:
	- Dated index/archive pages.
	- Sitemap
	- Category-based indexes
	- [twtxt](https://twtxt.readthedocs.io/) feed
- Generate an RSS feed using the metadata summary or the first html paragraph for the item description.
- In the header template, leverage metadata fields as well as the site configured variables. 
- Support for conditional sections in the header template.
- Transform all `.../page.md` markdown content to a format `.../page/index.html`. Respect all other naming convention and the flexibility of any web directory hierarchy.
- Allow symbolically linked content in the source directory. 
- Only build new or updated content.

### Requirements

- [lowdown](https://kristaps.bsd.lv/lowdown/)
- cpio
- Make

### Usage
