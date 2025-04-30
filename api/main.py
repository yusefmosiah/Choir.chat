from fastapi import FastAPI, HTTPException, Request # Added Request & HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates # Import Jinja2Templates
from pathlib import Path
import markdown # Import markdown library
import os
from datetime import datetime # For footer year

from app.routers import threads, users, balance, postchain, auth, vectors, notifications
from app.config import Config

app = FastAPI(title="Choir API", version="1.0.0")

config = Config.from_env()

# --- Configure Jinja2 Templating ---
# Assumes main.py is in 'api/' directory
templates = Jinja2Templates(directory="templates")
# --- End Jinja2 Configuration ---

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Helper Function to Read and Convert Markdown ---
def render_markdown_to_html(request: Request, md_file_path: Path, page_title: str) -> HTMLResponse:
    if not md_file_path.is_file():
        raise HTTPException(status_code=404, detail=f"{md_file_path.name} not found")
    try:
        md_content = md_file_path.read_text()
        # Convert Markdown to HTML using extensions for better formatting
        html_content = markdown.markdown(
            md_content,
            extensions=['fenced_code', 'tables', 'footnotes', 'attr_list', 'md_in_html']
        )
        # Render using the base template
        return templates.TemplateResponse(
            "base.html",
            {
                "request": request,
                "title": page_title,
                "content": html_content,
                "current_year": datetime.now().year
            }
        )
    except Exception as e:
        # Log the error for debugging
        print(f"Error rendering markdown file {md_file_path}: {e}")
        raise HTTPException(status_code=500, detail="Error rendering page")
# --- End Helper Function ---


# --- Root Route (Landing Page) ---
@app.get("/", response_class=HTMLResponse)
async def read_landing_page(request: Request):
    """Serves the landing page rendered from Markdown."""
    root_dir = Path(__file__).parent
    md_path = root_dir / "content" / "landing.md"
    return render_markdown_to_html(request, md_path, "Welcome to Choir")

# --- Privacy Policy ---
@app.get("/privacy", response_class=HTMLResponse)
async def privacy_policy(request: Request):
    """Serves the privacy policy page rendered from Markdown."""
    root_dir = Path(__file__).parent
    md_path = root_dir / "content" / "privacy.md"
    return render_markdown_to_html(request, md_path, "Choir Privacy Policy")

# --- Support Page ---
@app.get("/support", response_class=HTMLResponse)
async def support_page(request: Request):
    """Serves the support page rendered from Markdown."""
    root_dir = Path(__file__).parent
    md_path = root_dir / "content" / "support.md"
    return render_markdown_to_html(request, md_path, "Choir Support")

# --- Marketing Page ---
@app.get("/marketing", response_class=HTMLResponse)
async def marketing_page(request: Request):
    """Serves the marketing page rendered from Markdown."""
    root_dir = Path(__file__).parent
    md_path = root_dir / "content" / "marketing.md"
    return render_markdown_to_html(request, md_path, "About Choir")

# --- Health Check ---
@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# --- API Routers ---
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(threads.router, prefix="/api/threads", tags=["threads"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(balance.router, prefix="/api/balance", tags=["balance"])
app.include_router(postchain.router, prefix="/api/postchain", tags=["postchain"])
app.include_router(vectors.router, prefix="/api/vectors", tags=["vectors"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])


# --- Blog Routes (Modified) ---
@app.get("/blog", response_class=HTMLResponse)
async def blog_index(request: Request):
    """Render blog index page with links to all blog posts."""
    root_dir = Path(__file__).parent
    blog_dir = root_dir / "blog"
    try:
        md_files = sorted([f for f in blog_dir.glob("*.md") if f.is_file()])
    except FileNotFoundError:
         raise HTTPException(status_code=404, detail="Blog directory not found")

    # Generate simple HTML list for the index
    list_items_html = ""
    for md_file in md_files:
        post_slug = md_file.stem
        # Attempt to read title from markdown file (e.g., first H1)
        try:
            first_line = md_file.read_text().splitlines()[0]
            if first_line.startswith('# '):
                post_title = first_line[2:].strip()
            else:
                post_title = post_slug.replace("_", " ").title()
        except Exception:
             post_title = post_slug.replace("_", " ").title() # Fallback title

        list_items_html += f'<li><a href="/blog/{post_slug}">{post_title}</a></li>'

    # Wrap list in basic HTML structure using the template
    index_content_html = f"<h1>Choir Blog</h1>\n<ul>{list_items_html}</ul>"

    return templates.TemplateResponse(
        "base.html",
        {
            "request": request,
            "title": "Choir Blog",
            "content": index_content_html,
            "current_year": datetime.now().year
        }
    )

@app.get("/blog/{post_id}", response_class=HTMLResponse)
async def blog_post(request: Request, post_id: str):
    """Render a specific blog post from Markdown using the base template."""
    root_dir = Path(__file__).parent
    blog_dir = root_dir / "blog"
    md_path = blog_dir / f"{post_id}.md"

    # Try to get title from first H1, fallback to slug
    page_title = post_id.replace("_", " ").title() # Default title
    if md_path.is_file():
         try:
            first_line = md_path.read_text().splitlines()[0]
            if first_line.startswith('# '):
                page_title = first_line[2:].strip()
         except Exception:
             pass # Keep default title if error reading

    return render_markdown_to_html(request, md_path, page_title)
# --- End Blog Routes ---


# --- Static Files Mounting ---
# Mount the 'static' directory AFTER specific routes
# This serves files from api/static/ at the /static URL path
app.mount("/static", StaticFiles(directory="static"), name="static")
# --- End Static Files Mounting ---
