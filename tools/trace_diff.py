#!/usr/bin/env python3

import sys


def parse_trace_line(line):
    """
    瑙ｆ瀽涓€琛?trace锛屾牸寮忕害瀹氫负锛?        PC WE RD WDATA
    渚嬪锛?        80000000 1 01 00000010
    涓棿鐢ㄧ┖鏍煎垎闅旓紝鍧囦负16杩涘埗鎴栧崄杩涘埗鏁板瓧銆?    """
    line = line.strip()
    if not line or line.startswith("#"):
        return None

    parts = line.split()
    if len(parts) != 4:
        raise ValueError(f"闈炴硶鐨?trace 琛屾牸寮? {line}")

    pc_str, we_str, rd_str, wdata_str = parts

    pc = int(pc_str, 16)
    we = int(we_str, 0)
    rd = int(rd_str, 0)
    wdata = int(wdata_str, 16)

    return pc, we, rd, wdata


def load_trace(path):
    events = []
    with open(path, "r") as f:
        for line in f:
            try:
                parsed = parse_trace_line(line)
            except ValueError as e:
                print(f"[WARN] {e}", file=sys.stderr)
                continue
            if parsed is not None:
                events.append(parsed)
    return events


def format_event(ev):
    pc, we, rd, wdata = ev
    return f"pc=0x{pc:08x}, we={we}, rd={rd}, wdata=0x{wdata:08x}"


def main():
    if len(sys.argv) != 3:
        print("鐢ㄦ硶: python tools/trace_diff.py <golden_trace> <dut_trace>")
        sys.exit(1)

    golden_path = sys.argv[1]
    dut_path = sys.argv[2]

    golden_events = load_trace(golden_path)
    dut_events = load_trace(dut_path)

    n = min(len(golden_events), len(dut_events))

    for idx in range(n):
        g = golden_events[idx]
        d = dut_events[idx]

        if g != d:
            print("========== TRACE 涓嶄竴鑷?==========")
            print(f"绗?{idx + 1} 鏉″啓鍥炰簨浠跺彂鐢熶笉涓€鑷达細")
            print(f"  Golden: {format_event(g)}")
            print(f"  DUT   : {format_event(d)}")
            print("鎻愮ず锛氬湪娉㈠舰涓畾浣嶅埌瀵瑰簲鐨勫啓鍥炲懆鏈燂紝妫€鏌ヨ鎸囦护鐨勬墽琛岃矾寰勩€?)
            sys.exit(1)

    if len(golden_events) != len(dut_events):
        print("========== TRACE 闀垮害涓嶄竴鑷?==========")
        print(f"Golden 浜嬩欢鏁? {len(golden_events)}")
        print(f"DUT    浜嬩欢鏁? {len(dut_events)}")
        sys.exit(1)

    print("PASS: Golden Trace 涓?DUT Trace 瀹屽叏涓€鑷淬€?)


if __name__ == "__main__":
    main()

