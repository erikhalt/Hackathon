import argparse
"""
python3 --start "2011-2-1 00:00:00" --end "2011-2-1 00:00:00" -TBase 8.5
"""

def main(start, end, tbase):
    
    output = simon_function(start,end,tbase)
    print(output)





if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate CGDD based on input dates and base temperature")

    parser.add_argument('--start', type=str, required=True, help="Please input the start date (EX 2011-2-1 00:00:00)")
    parser.add_argument('--end', type=str, required=True, help="Please input the end date (EX 2011-2-1 00:00:00)")
    parser.add_argument('--tbase', type=float, default=5, help="Please input the T_Base (default is 5)")

    
    args = parser.parse_args()

    
    main(args.start, args.end, args.tbase)
