from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pathlib import Path
import markdown
import os
from app.routers import  threads, users, balance, postchain
from app.config import Config

app = FastAPI(title="Choir API", version="1.0.0")

config = Config.from_env()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers

app.include_router(threads.router, prefix="/api/threads", tags=["threads"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(balance.router, prefix="/api/balance", tags=["balance"])
app.include_router(postchain.router, prefix="/api/postchain", tags=["postchain"])

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Blog routes
@app.get("/blog", response_class=HTMLResponse)
async def blog_index():
    """Render blog index page with links to all blog posts."""
    # Get the project root directory
    root_dir = Path(__file__).parent
    blog_dir = root_dir / "blog"
    md_files = sorted(blog_dir.glob("*.md"))
    
    content = "<h1>Choir Blog</h1>\n<ul>"
    for md_file in md_files:
        post_name = md_file.stem.replace("_", " ").title()
        content += f'<li><a href="/blog/{md_file.stem}">{post_name}</a></li>'
    content += "</ul>"
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Choir Blog</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; padding: 1em; max-width: 50em; margin: 0 auto; }}
            pre {{ background: #f4f4f4; padding: 1em; overflow-x: auto; }}
            code {{ background: #f4f4f4; padding: 0.2em 0.4em; }}
            img {{ max-width: 100%; }}
        </style>
    </head>
    <body>
        {content}
    </body>
    </html>
    """

@app.get("/blog/{post_id}", response_class=HTMLResponse)
async def blog_post(post_id: str):
    """Render a specific blog post as HTML."""
    # Get the project root directory
    root_dir = Path(__file__).parent
    blog_dir = root_dir / "blog"
    md_file = blog_dir / f"{post_id}.md"
    
    if not md_file.exists():
        return HTMLResponse(content=f"<h1>Post not found: {post_id}</h1>", status_code=404)
    
    md_content = md_file.read_text()
    html_content = markdown.markdown(md_content, extensions=['fenced_code', 'tables'])
    post_title = post_id.replace("_", " ").title()
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>{post_title} - Choir Blog</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; padding: 1em; max-width: 50em; margin: 0 auto; }}
            pre {{ background: #f4f4f4; padding: 1em; overflow-x: auto; }}
            code {{ background: #f4f4f4; padding: 0.2em 0.4em; }}
            img {{ max-width: 100%; }}
        </style>
    </head>
    <body>
        <p><a href="/blog">← Back to all posts</a></p>
        <h1>{post_title}</h1>
        {html_content}
    </body>
    </html>
    """
