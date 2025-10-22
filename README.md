# Sucran's Blog

A modern, multilingual personal blog built with [Hugo](https://gohugo.io/) and the [Congo](https://github.com/jpanther/congo) theme.

## 🌏 Multilingual Support

This blog supports both **English** and **Chinese (Simplified)** content:

- **English** (Primary): `https://sucran.github.io/en/`
- **中文** (Secondary): `https://sucran.github.io/zh/`

Content files are organized with language-specific extensions:
- English: `*.en.md`
- Chinese: `*.zh.md`

## 🚀 Tech Stack

- **Static Site Generator**: [Hugo](https://gohugo.io/) (Extended version)
- **Theme**: [Congo](https://github.com/jpanther/congo) v2.12.2
- **Deployment**: GitHub Pages
- **Language Support**: Hugo's multilingual features
- **Module Management**: Hugo Modules (Go Modules)

## 🏗️ Development

### Prerequisites

- Hugo Extended (v0.87+)
- Go (v1.19+)
- Git

### Local Development

```bash
# Clone the repository
git clone https://github.com/sucran/sucran.github.io.git
cd sucran.github.io

# Install dependencies
hugo mod get -u github.com/jpanther/congo/v2

# Start development server
hugo server -D
```

The site will be available at `http://localhost:1313/`

### Adding New Content

#### English Content
```bash
hugo new posts/my-new-post.en.md
```

#### Chinese Content
```bash
hugo new posts/my-new-post.zh.md
```

### Configuration

- **Site Configuration**: `config/_default/hugo.toml`
- **Theme Configuration**: `config/_default/params.toml`
- **Language Settings**: `config/_default/languages.en.toml` / `config/_default/languages.zh.toml`
- **Navigation Menus**: `config/_default/menus.en.toml` / `config/_default/menus.zh.toml`

## 📁 Project Structure

```
├── archetypes/          # Content templates
├── assets/             # SCSS, JS files
├── config/_default/    # Hugo configuration files
├── content/            # Blog content
│   ├── posts/         # Blog posts
│   ├── tech/          # Technical articles
│   ├── life/          # Personal stories
│   ├── about/         # About page
│   ├── contact/       # Contact page
│   └── privacy/       # Privacy policy
├── data/              # Site data files
├── i18n/              # Translation files
├── layouts/           # Custom layouts (if needed)
├── static/            # Static files (images, etc.)
└── themes/            # Hugo themes (via modules)
```

## 🚀 Deployment

This blog is automatically deployed to GitHub Pages via GitHub Actions on every push to the `main` branch.

## 📝 Content Guidelines

- Use front matter for metadata: title, date, tags, categories
- Add appropriate tags and categories for better organization
- Include images in the `static/images/` directory
- Use proper Markdown formatting

## 🤝 Contributing

Feel free to open issues or submit pull requests for improvements.

## 📄 License

The content of this blog is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed)
The code is licensed under [MIT License](LICENSE).
