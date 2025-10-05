#!/usr/bin/env python3

def main():
    """Simple hello world plugin."""
    try:
        from rich.console import Console
        from rich.text import Text
        from rich.panel import Panel

        console = Console()

        # Create a fancy hello world message
        title = Text("Hello, World!", style="bold cyan")
        message = "Welcome to the [bold green]hello-world[/bold green] plugin!\n"
        message += "This plugin demonstrates [yellow]uv[/yellow] dependency management with [blue]rich[/blue] library."

        panel = Panel(message, title=title, border_style="bright_blue")
        console.print(panel)

        console.print("\n[dim]Press Enter to exit...[/dim]")
        input()

    except ImportError:
        # Fallback if rich is not available
        print("Hello, World from Actions All-In-One!")
        print("This is the hello-world plugin")
        print("Note: Rich library not available - install dependencies first")
        print("Press Enter to exit...")
        input()

if __name__ == "__main__":
    main()