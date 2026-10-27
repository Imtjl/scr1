# Лабораторная работа 2. Симуляция SCR1

Дворкин Борис Александрович, группа Р4130, ИСУ 368090

## Вариант 3

| Исключение | Тест | Reset Vector | Trap Vector | Обработчик |
|---|---|---|---|---|
| Illegal instruction | isa/rv32mi/illegal.S | 0x2000 | 0x1880 | вывод строки «illexc» |

Ветка `lab_scr1_sim`, симулятор Verilator 5.020, тулчейн riscv64-unknown-elf-gcc 13.2.0.

## Выбор теста (п. 3)

`sim/tests/riscv_isa/rv32_tests.inc`: в списке оставлен только тест по варианту.

```make
rv32_isa_tests += isa/rv32mi/illegal.S
```

## Reset Vector и Trap Vector (п. 5)

`src/includes/scr1_arch_description.svh`:

```systemverilog
parameter bit [`SCR1_XLEN-1:0] SCR1_ARCH_RST_VECTOR = 'h2000;
parameter bit [`SCR1_XLEN-1:0] SCR1_ARCH_MTVEC_BASE = 'h1880;
```

`src/tb/scr1_top_tb_ahb.sv`, `src/tb/scr1_top_tb_axi.sv`: тестбенч сверяет адреса `_start` и `trap_vector` из ELF с этими параметрами вместо констант 0x200 и 0x1C0.

```systemverilog
localparam ADDR_START        = SCR1_ARCH_RST_VECTOR;
localparam ADDR_TRAP_DEFAULT = SCR1_ARCH_MTVEC_BASE;
```

## Сборка программы (п. 6)

`sim/tests/common/link.ld`: секция `.text.trap` размещается с адреса 0x1880, `.text.init` с адреса 0x2000.

```ld
. = 0x1880;
PROVIDE(__TEXT_START__ = .);
*(.text.trap)
. = 0x2000;
*(.text.init)
```

`sim/tests/common/riscv_macros.h`: в `RVTEST_CODE_BEGIN` метка `trap_vector` помещена в секцию `.text.trap`, `_start` в `.text.init`; `.org 0xC0` и `.balign 64` удалены.

## Обработчик trap_vector (п. 4)

`sim/tests/common/riscv_macros.h`: при `mcause = 2` (illegal instruction) строка `illexc` побайтно записывается по адресу 0xF0000000, который тестбенч выводит в консоль. Регистр `a6` сохраняется в `mscratch` и восстанавливается после вывода, далее управление передаётся в `mtvec_handler` теста.

```asm
li a5, CAUSE_ILLEGAL_INSTRUCTION
bne a4, a5, 2f
csrw mscratch, a6
li a6, SCR1_SIM_PRINT_ADDR
la a4, illexc_msg
3: lbu a5, 0(a4)
beqz a5, 4f
sw a5, 0(a6)
addi a4, a4, 1
j 3b
4: csrr a6, mscratch
```

## Запуск

```sh
make clean
make run_verilator TARGETS="riscv_isa" TRACE=1
```

## Результат (п. 7)

```
---Test:                      illegal.hex
illexc
Test passed
# Summary: 1/1 tests passed
```

Из `results/illegal.dump`: `trap_vector` по адресу 0x1880, `_start` по адресу 0x2000. Из `results/tracelog_core_0.log`: после сброса ядро начинает выполнение с 0x2000, нелегальная инструкция по адресу 0x2104 вызывает исключение с `mcause = 2` и переход на 0x1880.

| Файл | Содержимое |
|---|---|
| `results/test_results.txt` | результат симуляции |
| `results/sim_results.txt` | вывод симуляции в консоль |
| `results/illegal.dump` | дизассемблер теста |
| `results/tracelog_core_0.log` | трейс лог ядра (текущая версия SCR1 пишет MPRF и CSR в один файл) |
| `results/trace_mprf_diff_0.log` | записи в регистры MPRF из трейс лога |
| `results/trace_csr_0.log` | записи в CSR из трейс лога |
