import asyncio
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1600, "height": 1200})
        print("Navigating to dashboard...")
        await page.goto("http://localhost:8000/dashboard/index.html")
        
        # Wait for charts to animate and render
        print("Waiting for charts to render...")
        await page.wait_for_timeout(3000)
        
        # Ensure assets directory exists
        import os
        os.makedirs("../assets", exist_ok=True)
        
        print("Taking screenshot...")
        await page.screenshot(path="../assets/dashboard_screenshot.png", full_page=True)
        print("Screenshot saved to assets/dashboard_screenshot.png")
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(main())
