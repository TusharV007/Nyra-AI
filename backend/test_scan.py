import asyncio
from scraper import run_deepfake_scan

async def test():
    try:
        results = await run_deepfake_scan('zuHxYn9txvUHioCaJRpuQjQD5Ks2', 'Tushar', 'https://upload.wikimedia.org/wikipedia/commons/a/a2/Tushar_Gandhi_2013-10-02_20-41.jpg')
        print(f"Success! {len(results)} results.")
        for r in results:
            print("Hash:", r.get('hash'))
    except Exception as e:
        import traceback
        traceback.print_exc()

asyncio.run(test())
