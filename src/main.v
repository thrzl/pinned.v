module main

import x.vweb
import net.http
import net.html
import lenni0451.timecache
import time

pub struct App {
pub mut:
	// In the app struct we store data that should be accessible by all endpoints.
	// For example, a database or configuration values.
	cache timecache.Cache[string, []Repo]
	// client Client @[required]
}

pub struct Repo {
pub:
	full_name      string
	name           string
	description    string
	link           string
	stars          int
	forks          int
	language_color string
	language       string
}

pub struct User {
pub mut:
    name string
    id   int
}

// Our context struct must embed `vweb.Context`!
pub struct Context {
    vweb.Context
pub mut:
    // In the context struct we store data that could be different
    // for each request. Like a User struct or a session id
    user       User
    session_id string
}


@['/:user']
pub fn (mut app App) get_user_pinned(mut ctx vweb.Context, user string) vweb.Result {
	if app.cache.contains(user) {
		return ctx.json(app.cache.get(user) or {[]})
	}
	url := 'https://github.com/${user}'
	res := http.get(url) or { http.Response{} }
	document := html.parse(res.body)
	li_tags := document.get_tags( html.GetTagsOptions{"li"})
	raw_repos := li_tags.filter(it.attributes["class"].contains("pinned-item-list-item"))
	mut repos := []Repo{}
	for raw_repo in raw_repos {
		full_name := raw_repo.get_tags_by_class_name('Link')[0].attributes['href'][1..]
		link := 'https://github.com/${full_name}'
		name := full_name.split('/')[1]
		description := raw_repo.get_tags_by_class_name('pinned-item-desc')[0].text().trim_space()
		language := raw_repo.get_tags_by_attribute_value('itemprop', 'programmingLanguage')[0].text()
		language_color := raw_repo.get_tags_by_class_name('repo-language-color')[0].attributes['style'].replace('background-color: ',
			'')
		mut forks := 0
		mut stars := 0

		meta := raw_repo.get_tags("a").filter(it.attributes["href"].starts_with("/${full_name}/"))
		// println("\n${meta}\n")
		
		// if raw_stars := raw_repo.get_tag_by_attribute_value('href', '/${full_name}/stargazers') {
		// 	stars = raw_stars.content.int()
		// }
		// if raw_forks := raw_repo.get_tag_by_attribute_value('href', '/${full_name}/forks') {
		// 	forks = raw_forks.content.int()
		// }
		for tag in meta {
			href := tag.attributes['href']
			if href.ends_with('/forks') {
				forks = tag.text().trim_space().int()
			} else if href.ends_with('/stargazers') {
				println("stars for ${full_name}: ${tag.text().trim_space()}")
				stars = tag.text().trim_space().int()
			} else {
				println(tag.content)
			}
		}

		repos << Repo{
            full_name
            name
            description
            link
            stars
            forks
            language_color
            language
		}
	}
	app.cache.put(user, repos)
	return ctx.json(repos)
}

// This is how endpoints are defined in vweb. This is the index route
pub fn (app &App) index(mut ctx vweb.Context) vweb.Result {
	return ctx.text('hi! visit /<username> to get a user\'s pinned repositories.\nhttps://github.com/thrzl/pinned.v')
}

fn main() {
	// mut cache := timecache.new_cache[string, []Repo{}]()
	
	mut cache := timecache.new_cache[string, []Repo]()

	cache.access_timeout(24 * time.hour)
	cache.write_timeout(24 * time.hour)
	mut app := &App{
		cache
	}
	// Pass the App and context type and start the web server on port 8080
	vweb.run[App, Context](mut app, 8080)
}