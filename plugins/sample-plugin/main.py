#!/usr/bin/env python3

import time
import sys

def main():
    """Sample plugin main function."""
    print("Sample Plugin Started!")
    print("=" * 40)
    print("This is a sample plugin for Actions All-In-One")
    print("Plugin Name: sample-plugin")
    print("Version: 1.0.0")
    print("=" * 40)

    # Test if dependencies are installed
    try:
        import requests
        import colorama
        from colorama import Fore, Style
        colorama.init()

        print(f"\n{Fore.GREEN}✅ Dependencies loaded successfully!{Style.RESET_ALL}")
        print(f"{Fore.BLUE}📦 requests version: {requests.__version__}{Style.RESET_ALL}")
        print(f"{Fore.BLUE}📦 colorama version: {colorama.__version__}{Style.RESET_ALL}")
    except ImportError as e:
        print(f"\n❌ Dependency import failed: {e}")

    print(f"\n{Fore.YELLOW}Running for 5 seconds...{Style.RESET_ALL}")
    for i in range(5, 0, -1):
        print(f"{Fore.CYAN}Countdown: {i}{Style.RESET_ALL}")
        time.sleep(1)

    print(f"\n{Fore.GREEN}Sample plugin execution completed!{Style.RESET_ALL}")
    print("Press any key to exit...")
    input()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nPlugin interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}")
        input()
        sys.exit(1)