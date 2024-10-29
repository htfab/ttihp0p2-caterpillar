import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles
import itertools
import os


@cocotb.test()
async def check_project(dut):

    clock = Clock(dut.clk, 20, units="us")
    cocotb.start_soon(clock.start())

    dut._log.info("starting simulation")
    dut.ena.value = 1
    dut.buttons.value = 0
    dut.seg_invert.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 4)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 4)
    assert dut.leds.value == 0b0100
    assert dut.segments_pov.value == 0b0000000_0000110
    dut._log.info("reset => level 1, blue")

    dut.buttons.value = 0b0100
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0010
    dut._log.info("short-press blue => green")

    dut.buttons.value = 0b1000
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0001
    dut._log.info("short-press yellow => red")

    dut.buttons.value = 0b0100
    await ClockCycles(dut.clk, 25000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 50000)
    assert dut.leds.value == 0b0100
    dut._log.info("long-press blue, wait => blue")
    await ClockCycles(dut.clk, 25000)
    assert dut.leds.value == 0b1000
    dut._log.info("wait => yellow")
    await ClockCycles(dut.clk, 50000)
    assert dut.leds.value == 0b0001
    dut._log.info("wait => red")

    dut.buttons.value = 0b0100
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0010
    dut._log.info("short-press blue => green")

    dut.buttons.value = 0b1000
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0001
    dut._log.info("short-press yellow => red")

    dut.buttons.value = 0b0100
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0010
    dut._log.info("short-press blue => green")

    dut.buttons.value = 0b1000
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0001
    dut._log.info("short-press yellow => red")

    dut.buttons.value = 0b0100
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b1010
    dut._log.info("short-press blue => green, yellow")

    dut.buttons.value = 0b1000
    await ClockCycles(dut.clk, 25000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0001
    dut._log.info("long-press yellow, wait => red")
    
    dut.buttons.value = 0b0001
    await ClockCycles(dut.clk, 25000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0100
    dut._log.info("long-press red, wait => blue")

    dut.buttons.value = 0b0010
    await ClockCycles(dut.clk, 25000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0000
    assert dut.segments_pov.value == 0b0000000_0000000
    dut._log.info("long-press green, wait => challenge mode")

    questions = []
    for i in range(2):
        dut._log.info(f"waiting for challenge")
        question = []
        for j in range(100):
            await ClockCycles(dut.clk, 1000)
            if dut.leds.value != 0b0000:
                break
        assert dut.leds.value != 0b0000
        for j in range(6):
            question.append(int(dut.leds.value))
            for k in range(30):
                await ClockCycles(dut.clk, 1000)
                if dut.leds.value == 0b0000:
                    break
            assert dut.leds.value == 0b0000
            for k in range(10):
                await ClockCycles(dut.clk, 1000)
                if dut.leds.value != 0b0000:
                    break
            if dut.leds.value == 0b0000:
                break
        assert dut.leds.value == 0b0000
        await ClockCycles(dut.clk, 25000)
        questions.append(question)
        if i == 1:
            assert questions[1] == questions[0]
        answer = question != question[::-1]
        dut._log.info("sending interjection")
        if i == 1:
            dut.buttons.value = 0b0011
        else:
            dut.buttons.value = 0b1100
        await ClockCycles(dut.clk, 5000)
        dut.buttons.value = 0b0000
        await ClockCycles(dut.clk, 5000)
        if i == 1:
            assert dut.segments_pov.value == 0b0000000_0000000
        else:
            assert dut.segments_pov.value == 0b0000001_0000000
        q_text = ' '.join({1: 'red', 2: 'green', 4: 'blue', 8: 'yellow'}[j] for j in question)
        a_text = ('green' if answer else 'red') if i == 1 else 'blue'
        dut._log.info(f"sending answer ({q_text} => {a_text})")
        if i == 1:
            dut.buttons.value = 0b0010 if answer else 0b0001
        else:
            dut.buttons.value = 0b0100
        await ClockCycles(dut.clk, 5000)
        dut.buttons.value = 0b0000
        await ClockCycles(dut.clk, 5000)
    dut._log.info("waiting for exploration mode")
    await ClockCycles(dut.clk, 100000)
    assert dut.leds.value == 0b0100
    assert dut.segments_pov.value == 0b0000000_0000110
    dut._log.info("exploration mode, level 1")

    dut.buttons.value = 0b1100
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0100
    assert dut.segments_pov.value == 0b0000000_1011011
    dut._log.info("short-press blue + yellow => level 2")

    dut.buttons.value = 0b0011
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0100
    assert dut.segments_pov.value == 0b0000000_0000110
    dut._log.info("short-press red + green => level 1")
    
    dut.buttons.value = 0b0101
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 250000)
    assert dut.leds.value == 0b0001
    dut._log.info("short-press red + blue => red")

    dut.buttons.value = 0b1010
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 250000)
    assert dut.leds.value == 0b0010
    dut._log.info("short-press green + yellow => green")

    dut.buttons.value = 0b0010
    await ClockCycles(dut.clk, 25000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0000
    assert dut.segments_pov.value == 0b0000000_0000000
    dut._log.info("long-press green, wait => challenge mode")

    await ClockCycles(dut.clk, 250000)
    dut.buttons.value = 0b1001
    await ClockCycles(dut.clk, 5000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0100
    assert dut.segments_pov.value == 0b0000000_0000110
    dut._log.info("short-press red + yellow => exploration mode")

    dut.buttons.value = 0b0010
    await ClockCycles(dut.clk, 25000)
    dut.buttons.value = 0b0000
    await ClockCycles(dut.clk, 5000)
    assert dut.leds.value == 0b0000
    assert dut.segments_pov.value == 0b0000000_0000000
    dut._log.info("long-press green, wait => challenge mode")

    for i in range(15):
        assert int(dut.segments_pov.value).bit_count() == i
        dut._log.info(f"round {i}: waiting for challenge")
        question = []
        for j in range(100):
            await ClockCycles(dut.clk, 1000)
            if dut.leds.value != 0b0000:
                break
        assert dut.leds.value != 0b0000
        for j in range(6):
            question.append(int(dut.leds.value))
            for k in range(30):
                await ClockCycles(dut.clk, 1000)
                if dut.leds.value == 0b0000:
                    break
            assert dut.leds.value == 0b0000
            for k in range(10):
                await ClockCycles(dut.clk, 1000)
                if dut.leds.value != 0b0000:
                    break
            if dut.leds.value == 0b0000:
                break
        assert dut.leds.value == 0b0000
        await ClockCycles(dut.clk, 25000)
        answer = question == question[::-1]
        q_text = ' '.join({1: 'red', 2: 'green', 4: 'blue', 8: 'yellow'}[j] for j in question)
        a_text = 'green' if answer else 'red'
        dut._log.info(f"round {i}: sending answer ({q_text} => {a_text})")
        dut.buttons.value = 0b0010 if answer else 0b0001
        await ClockCycles(dut.clk, 5000)
        dut.buttons.value = 0b0000
        await ClockCycles(dut.clk, 5000)
        
    dut._log.info("waiting for next level")
    await ClockCycles(dut.clk, 200000)
    assert dut.leds.value == 0b0100
    assert dut.segments_pov.value == 0b0000000_1011011
    dut._log.info("finished")


def rules(seq):
    seqstr = ''.join(map(str, seq))
    blocks = [(x, len(list(v))) for (x, v) in itertools.groupby(seq)]
    runs = [y for (x, y) in blocks]
    valid_bits = (
        seq == seq[::-1],
        seq[0] != seq[-1],
        1 in seq,
        0 not in seq or 3 not in seq,
        len(set(seq)) == 3,
        seq.count(0) == 3,
        seq.count(3) > seq.count(2),
        '02' not in seqstr and '20' not in seqstr,
        seq.count(0) + seq.count(3) == 5,
        min(runs) == 2,
        len(blocks) == 4,
        [x for (x, y) in blocks].count(1) == 2,
        runs.count(2) == 2,
        max(runs) == 2,
        runs == sorted(runs) or runs == sorted(runs, reverse=True),
        len(set(seq.count(c) for c in set(seq))) == 1,
        runs.count(max(runs)) == 1,
        len(set(blocks)) == 3,
        runs.count(min(runs)) == 1,
        len(blocks) == len(set(blocks)),
    )
    return valid_bits

async def ticktock(dut):
    await Timer(10, units='ns')
    dut.fsm_clk.value = 1
    await Timer(20, units='ns')
    dut.fsm_clk.value = 0
    await Timer(10, units='ns')

def dump_state(dut):
    return (dut.fsm.length.value, dut.fsm.seq.value, dut.fsm.color_count.value, dut.fsm.num_blocks.value,
            dut.fsm.len1_block_count.value, dut.fsm.len2_block_count.value, dut.fsm.len3_block_count.value,
            dut.fsm.block_len.value, dut.fsm.green_block_count.value,
            dut.fsm.len1_color_count.value, dut.fsm.len2_color_count.value, dut.fsm.len3_color_count.value)

async def test_seq(dut, seq):
    dut.fsm_reset.value = 1
    dut.fsm_update.value = 0
    dut.fsm_erase.value = 0
    dut.fsm_color.value = 0
    await ticktock(dut)
    dut.fsm_reset.value = 0
    dut.fsm_update.value = 1
    for i in seq:
        dut.fsm_color.value = i
        await ticktock(dut)
    baseline = rules(seq)
    for i in range(20):
        assert dut.fsm_valid[i].value == int(baseline[i])

async def test_erase(dut, seq):
    dut.fsm_reset.value = 1
    dut.fsm_update.value = 0
    dut.fsm_erase.value = 0
    dut.fsm_color.value = 0
    await ticktock(dut)
    dut.fsm_reset.value = 0
    dut.fsm_update.value = 1
    for i in seq[:-1]:
        dut.fsm_color.value = i
        await ticktock(dut)
    pre = dump_state(dut)
    dut.fsm_color.value = seq[-1]
    await ticktock(dut)
    dut.fsm_update.value = 0
    dut.fsm_erase.value = 1
    await ticktock(dut)
    post = dump_state(dut)
    assert pre == post

async def test_readback(dut, seq):
    dut.fsm_reset.value = 1
    dut.fsm_update.value = 0
    dut.fsm_erase.value = 0
    dut.fsm_color.value = 0
    await ticktock(dut)
    dut.fsm_reset.value = 0
    dut.fsm_update.value = 1
    for i in seq:
        dut.fsm_color.value = i
        await ticktock(dut)
    dut.fsm_update.value = 0
    for i in range(8):
        dut.fsm_read_pos.value = i
        await ticktock(dut)
        if i < len(seq):
            assert dut.fsm_read_val.value == seq[i]
            assert dut.fsm_read_over.value == 0
        else:
            assert dut.fsm_read_over.value == 1

@cocotb.test()
async def check_rules(dut):
    if 'GATES' not in os.environ:
        for length in range(1, 8):
            for seq in itertools.product(range(4), repeat=length):
                print(f'Testing {seq}')
                await test_seq(dut, seq)

@cocotb.test()
async def check_erase(dut):
    if 'GATES' not in os.environ:
        for length in range(1, 8):
            for seq in itertools.product(range(4), repeat=length):
                print(f'Testing {seq}')
                await test_erase(dut, seq)

@cocotb.test()
async def check_readback(dut):
    if 'GATES' not in os.environ:
        for length in range(1, 8):
            for seq in itertools.product(range(4), repeat=length):
                print(f'Testing {seq}')
                await test_readback(dut, seq)

