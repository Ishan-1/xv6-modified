
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8f013103          	ld	sp,-1808(sp) # 800088f0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	90070713          	addi	a4,a4,-1792 # 80008950 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	4ce78793          	addi	a5,a5,1230 # 80006530 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbb227>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f7078793          	addi	a5,a5,-144 # 8000101c <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	690080e7          	jalr	1680(ra) # 800027ba <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	90650513          	addi	a0,a0,-1786 # 80010a90 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	be8080e7          	jalr	-1048(ra) # 80000d7a <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8f648493          	addi	s1,s1,-1802 # 80010a90 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	98690913          	addi	s2,s2,-1658 # 80010b28 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9d2080e7          	jalr	-1582(ra) # 80001b92 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	43c080e7          	jalr	1084(ra) # 80002604 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	17a080e7          	jalr	378(ra) # 80002350 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	552080e7          	jalr	1362(ra) # 80002764 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	86a50513          	addi	a0,a0,-1942 # 80010a90 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	c00080e7          	jalr	-1024(ra) # 80000e2e <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	85450513          	addi	a0,a0,-1964 # 80010a90 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	bea080e7          	jalr	-1046(ra) # 80000e2e <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8af72b23          	sw	a5,-1866(a4) # 80010b28 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7c450513          	addi	a0,a0,1988 # 80010a90 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	aa6080e7          	jalr	-1370(ra) # 80000d7a <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	51e080e7          	jalr	1310(ra) # 80002810 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	79650513          	addi	a0,a0,1942 # 80010a90 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b2c080e7          	jalr	-1236(ra) # 80000e2e <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	77270713          	addi	a4,a4,1906 # 80010a90 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	74878793          	addi	a5,a5,1864 # 80010a90 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7b27a783          	lw	a5,1970(a5) # 80010b28 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	70670713          	addi	a4,a4,1798 # 80010a90 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6f648493          	addi	s1,s1,1782 # 80010a90 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6ba70713          	addi	a4,a4,1722 # 80010a90 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	74f72223          	sw	a5,1860(a4) # 80010b30 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	67e78793          	addi	a5,a5,1662 # 80010a90 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ec7ab23          	sw	a2,1782(a5) # 80010b2c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ea50513          	addi	a0,a0,1770 # 80010b28 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f6e080e7          	jalr	-146(ra) # 800023b4 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	63050513          	addi	a0,a0,1584 # 80010a90 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	882080e7          	jalr	-1918(ra) # 80000cea <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00242797          	auipc	a5,0x242
    8000047c:	fc878793          	addi	a5,a5,-56 # 80242440 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6007a223          	sw	zero,1540(a5) # 80010b50 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b7a50513          	addi	a0,a0,-1158 # 800080e8 <digits+0xa8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	38f72823          	sw	a5,912(a4) # 80008910 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	594dad83          	lw	s11,1428(s11) # 80010b50 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	53e50513          	addi	a0,a0,1342 # 80010b38 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	778080e7          	jalr	1912(ra) # 80000d7a <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3e050513          	addi	a0,a0,992 # 80010b38 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	6ce080e7          	jalr	1742(ra) # 80000e2e <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3c448493          	addi	s1,s1,964 # 80010b38 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	564080e7          	jalr	1380(ra) # 80000cea <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	38450513          	addi	a0,a0,900 # 80010b58 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	50e080e7          	jalr	1294(ra) # 80000cea <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	536080e7          	jalr	1334(ra) # 80000d2e <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1107a783          	lw	a5,272(a5) # 80008910 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	5a8080e7          	jalr	1448(ra) # 80000dce <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0e07b783          	ld	a5,224(a5) # 80008918 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0e073703          	ld	a4,224(a4) # 80008920 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2f6a0a13          	addi	s4,s4,758 # 80010b58 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0ae48493          	addi	s1,s1,174 # 80008918 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0ae98993          	addi	s3,s3,174 # 80008920 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b20080e7          	jalr	-1248(ra) # 800023b4 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	28850513          	addi	a0,a0,648 # 80010b58 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	4a2080e7          	jalr	1186(ra) # 80000d7a <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0307a783          	lw	a5,48(a5) # 80008910 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	03673703          	ld	a4,54(a4) # 80008920 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0267b783          	ld	a5,38(a5) # 80008918 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	25a98993          	addi	s3,s3,602 # 80010b58 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	01248493          	addi	s1,s1,18 # 80008918 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	01290913          	addi	s2,s2,18 # 80008920 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a32080e7          	jalr	-1486(ra) # 80002350 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	22448493          	addi	s1,s1,548 # 80010b58 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fce7bc23          	sd	a4,-40(a5) # 80008920 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	4d4080e7          	jalr	1236(ra) # 80000e2e <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	19e48493          	addi	s1,s1,414 # 80010b58 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	3b6080e7          	jalr	950(ra) # 80000d7a <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	458080e7          	jalr	1112(ra) # 80000e2e <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <get_ref_index>:

struct spinlock ref_lock;
int reference_arr[PGROUNDUP(PHYSTOP) >> 12];

uint64 get_ref_index(void *pa)
{
    800009e8:	1141                	addi	sp,sp,-16
    800009ea:	e422                	sd	s0,8(sp)
    800009ec:	0800                	addi	s0,sp,16
  return (uint64)pa >> 12;
}
    800009ee:	8131                	srli	a0,a0,0xc
    800009f0:	6422                	ld	s0,8(sp)
    800009f2:	0141                	addi	sp,sp,16
    800009f4:	8082                	ret

00000000800009f6 <init_ref>:

void init_ref()
{
    800009f6:	1101                	addi	sp,sp,-32
    800009f8:	ec06                	sd	ra,24(sp)
    800009fa:	e822                	sd	s0,16(sp)
    800009fc:	e426                	sd	s1,8(sp)
    800009fe:	1000                	addi	s0,sp,32
  initlock(&ref_lock, "ref_lock");
    80000a00:	00010497          	auipc	s1,0x10
    80000a04:	19048493          	addi	s1,s1,400 # 80010b90 <ref_lock>
    80000a08:	00007597          	auipc	a1,0x7
    80000a0c:	65858593          	addi	a1,a1,1624 # 80008060 <digits+0x20>
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2d8080e7          	jalr	728(ra) # 80000cea <initlock>
  acquire(&ref_lock);
    80000a1a:	8526                	mv	a0,s1
    80000a1c:	00000097          	auipc	ra,0x0
    80000a20:	35e080e7          	jalr	862(ra) # 80000d7a <acquire>
  for (uint64 i = 0; i < (PGROUNDUP(PHYSTOP) >> 12); i++)
    80000a24:	00010797          	auipc	a5,0x10
    80000a28:	1a478793          	addi	a5,a5,420 # 80010bc8 <reference_arr>
    80000a2c:	00230717          	auipc	a4,0x230
    80000a30:	19c70713          	addi	a4,a4,412 # 80230bc8 <pid_lock>
  {
    reference_arr[i] = 0;
    80000a34:	0007a023          	sw	zero,0(a5)
  for (uint64 i = 0; i < (PGROUNDUP(PHYSTOP) >> 12); i++)
    80000a38:	0791                	addi	a5,a5,4
    80000a3a:	fee79de3          	bne	a5,a4,80000a34 <init_ref+0x3e>
  }
  release(&ref_lock);
    80000a3e:	00010517          	auipc	a0,0x10
    80000a42:	15250513          	addi	a0,a0,338 # 80010b90 <ref_lock>
    80000a46:	00000097          	auipc	ra,0x0
    80000a4a:	3e8080e7          	jalr	1000(ra) # 80000e2e <release>
}
    80000a4e:	60e2                	ld	ra,24(sp)
    80000a50:	6442                	ld	s0,16(sp)
    80000a52:	64a2                	ld	s1,8(sp)
    80000a54:	6105                	addi	sp,sp,32
    80000a56:	8082                	ret

0000000080000a58 <inc_ref>:

void inc_ref(void *pa)
{
    80000a58:	1101                	addi	sp,sp,-32
    80000a5a:	ec06                	sd	ra,24(sp)
    80000a5c:	e822                	sd	s0,16(sp)
    80000a5e:	e426                	sd	s1,8(sp)
    80000a60:	1000                	addi	s0,sp,32
    80000a62:	84aa                	mv	s1,a0
  acquire(&ref_lock);
    80000a64:	00010517          	auipc	a0,0x10
    80000a68:	12c50513          	addi	a0,a0,300 # 80010b90 <ref_lock>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	30e080e7          	jalr	782(ra) # 80000d7a <acquire>
  return (uint64)pa >> 12;
    80000a74:	00c4d513          	srli	a0,s1,0xc
  uint64 i = get_ref_index(pa);
  if (reference_arr[i] >= 0)
    80000a78:	00251713          	slli	a4,a0,0x2
    80000a7c:	00010797          	auipc	a5,0x10
    80000a80:	14c78793          	addi	a5,a5,332 # 80010bc8 <reference_arr>
    80000a84:	97ba                	add	a5,a5,a4
    80000a86:	439c                	lw	a5,0(a5)
    80000a88:	0207c763          	bltz	a5,80000ab6 <inc_ref+0x5e>
  {
    reference_arr[i] += 1;
    80000a8c:	853a                	mv	a0,a4
    80000a8e:	00010717          	auipc	a4,0x10
    80000a92:	13a70713          	addi	a4,a4,314 # 80010bc8 <reference_arr>
    80000a96:	972a                	add	a4,a4,a0
    80000a98:	2785                	addiw	a5,a5,1
    80000a9a:	c31c                	sw	a5,0(a4)
    release(&ref_lock);
    80000a9c:	00010517          	auipc	a0,0x10
    80000aa0:	0f450513          	addi	a0,a0,244 # 80010b90 <ref_lock>
    80000aa4:	00000097          	auipc	ra,0x0
    80000aa8:	38a080e7          	jalr	906(ra) # 80000e2e <release>
  else
  {
    panic("inc_ref");
    return;
  }
}
    80000aac:	60e2                	ld	ra,24(sp)
    80000aae:	6442                	ld	s0,16(sp)
    80000ab0:	64a2                	ld	s1,8(sp)
    80000ab2:	6105                	addi	sp,sp,32
    80000ab4:	8082                	ret
    panic("inc_ref");
    80000ab6:	00007517          	auipc	a0,0x7
    80000aba:	5ba50513          	addi	a0,a0,1466 # 80008070 <digits+0x30>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	a82080e7          	jalr	-1406(ra) # 80000540 <panic>

0000000080000ac6 <dec_ref>:

void dec_ref(void *pa)
{
    80000ac6:	1101                	addi	sp,sp,-32
    80000ac8:	ec06                	sd	ra,24(sp)
    80000aca:	e822                	sd	s0,16(sp)
    80000acc:	e426                	sd	s1,8(sp)
    80000ace:	1000                	addi	s0,sp,32
    80000ad0:	84aa                	mv	s1,a0
  acquire(&ref_lock);
    80000ad2:	00010517          	auipc	a0,0x10
    80000ad6:	0be50513          	addi	a0,a0,190 # 80010b90 <ref_lock>
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	2a0080e7          	jalr	672(ra) # 80000d7a <acquire>
  return (uint64)pa >> 12;
    80000ae2:	00c4d513          	srli	a0,s1,0xc
  uint64 i = get_ref_index(pa);
  if (reference_arr[i] > 0)
    80000ae6:	00251713          	slli	a4,a0,0x2
    80000aea:	00010797          	auipc	a5,0x10
    80000aee:	0de78793          	addi	a5,a5,222 # 80010bc8 <reference_arr>
    80000af2:	97ba                	add	a5,a5,a4
    80000af4:	439c                	lw	a5,0(a5)
    80000af6:	02f05763          	blez	a5,80000b24 <dec_ref+0x5e>
  {
    reference_arr[i] -= 1;
    80000afa:	853a                	mv	a0,a4
    80000afc:	00010717          	auipc	a4,0x10
    80000b00:	0cc70713          	addi	a4,a4,204 # 80010bc8 <reference_arr>
    80000b04:	972a                	add	a4,a4,a0
    80000b06:	37fd                	addiw	a5,a5,-1
    80000b08:	c31c                	sw	a5,0(a4)
    release(&ref_lock);
    80000b0a:	00010517          	auipc	a0,0x10
    80000b0e:	08650513          	addi	a0,a0,134 # 80010b90 <ref_lock>
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	31c080e7          	jalr	796(ra) # 80000e2e <release>
  else
  {
    panic("dec_ref");
    return;
  }
}
    80000b1a:	60e2                	ld	ra,24(sp)
    80000b1c:	6442                	ld	s0,16(sp)
    80000b1e:	64a2                	ld	s1,8(sp)
    80000b20:	6105                	addi	sp,sp,32
    80000b22:	8082                	ret
    panic("dec_ref");
    80000b24:	00007517          	auipc	a0,0x7
    80000b28:	55450513          	addi	a0,a0,1364 # 80008078 <digits+0x38>
    80000b2c:	00000097          	auipc	ra,0x0
    80000b30:	a14080e7          	jalr	-1516(ra) # 80000540 <panic>

0000000080000b34 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000b34:	7179                	addi	sp,sp,-48
    80000b36:	f406                	sd	ra,40(sp)
    80000b38:	f022                	sd	s0,32(sp)
    80000b3a:	ec26                	sd	s1,24(sp)
    80000b3c:	e84a                	sd	s2,16(sp)
    80000b3e:	e44e                	sd	s3,8(sp)
    80000b40:	1800                	addi	s0,sp,48
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000b42:	03451793          	slli	a5,a0,0x34
    80000b46:	e3a9                	bnez	a5,80000b88 <kfree+0x54>
    80000b48:	84aa                	mv	s1,a0
    80000b4a:	00243797          	auipc	a5,0x243
    80000b4e:	a8e78793          	addi	a5,a5,-1394 # 802435d8 <end>
    80000b52:	02f56b63          	bltu	a0,a5,80000b88 <kfree+0x54>
    80000b56:	47c5                	li	a5,17
    80000b58:	07ee                	slli	a5,a5,0x1b
    80000b5a:	02f57763          	bgeu	a0,a5,80000b88 <kfree+0x54>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  dec_ref(pa);
    80000b5e:	00000097          	auipc	ra,0x0
    80000b62:	f68080e7          	jalr	-152(ra) # 80000ac6 <dec_ref>
  return (uint64)pa >> 12;
    80000b66:	00c4d713          	srli	a4,s1,0xc
  if (reference_arr[get_ref_index(pa)] == 0)
    80000b6a:	070a                	slli	a4,a4,0x2
    80000b6c:	00010797          	auipc	a5,0x10
    80000b70:	05c78793          	addi	a5,a5,92 # 80010bc8 <reference_arr>
    80000b74:	97ba                	add	a5,a5,a4
    80000b76:	439c                	lw	a5,0(a5)
    80000b78:	c385                	beqz	a5,80000b98 <kfree+0x64>
    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
  }
}
    80000b7a:	70a2                	ld	ra,40(sp)
    80000b7c:	7402                	ld	s0,32(sp)
    80000b7e:	64e2                	ld	s1,24(sp)
    80000b80:	6942                	ld	s2,16(sp)
    80000b82:	69a2                	ld	s3,8(sp)
    80000b84:	6145                	addi	sp,sp,48
    80000b86:	8082                	ret
    panic("kfree");
    80000b88:	00007517          	auipc	a0,0x7
    80000b8c:	4f850513          	addi	a0,a0,1272 # 80008080 <digits+0x40>
    80000b90:	00000097          	auipc	ra,0x0
    80000b94:	9b0080e7          	jalr	-1616(ra) # 80000540 <panic>
    memset(pa, 1, PGSIZE);
    80000b98:	6605                	lui	a2,0x1
    80000b9a:	4585                	li	a1,1
    80000b9c:	8526                	mv	a0,s1
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	2d8080e7          	jalr	728(ra) # 80000e76 <memset>
    acquire(&kmem.lock);
    80000ba6:	00010997          	auipc	s3,0x10
    80000baa:	fea98993          	addi	s3,s3,-22 # 80010b90 <ref_lock>
    80000bae:	00010917          	auipc	s2,0x10
    80000bb2:	ffa90913          	addi	s2,s2,-6 # 80010ba8 <kmem>
    80000bb6:	854a                	mv	a0,s2
    80000bb8:	00000097          	auipc	ra,0x0
    80000bbc:	1c2080e7          	jalr	450(ra) # 80000d7a <acquire>
    r->next = kmem.freelist;
    80000bc0:	0309b783          	ld	a5,48(s3)
    80000bc4:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000bc6:	0299b823          	sd	s1,48(s3)
    release(&kmem.lock);
    80000bca:	854a                	mv	a0,s2
    80000bcc:	00000097          	auipc	ra,0x0
    80000bd0:	262080e7          	jalr	610(ra) # 80000e2e <release>
}
    80000bd4:	b75d                	j	80000b7a <kfree+0x46>

0000000080000bd6 <freerange>:
{
    80000bd6:	7139                	addi	sp,sp,-64
    80000bd8:	fc06                	sd	ra,56(sp)
    80000bda:	f822                	sd	s0,48(sp)
    80000bdc:	f426                	sd	s1,40(sp)
    80000bde:	f04a                	sd	s2,32(sp)
    80000be0:	ec4e                	sd	s3,24(sp)
    80000be2:	e852                	sd	s4,16(sp)
    80000be4:	e456                	sd	s5,8(sp)
    80000be6:	0080                	addi	s0,sp,64
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000be8:	6785                	lui	a5,0x1
    80000bea:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000bee:	00e504b3          	add	s1,a0,a4
    80000bf2:	777d                	lui	a4,0xfffff
    80000bf4:	8cf9                	and	s1,s1,a4
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bf6:	94be                	add	s1,s1,a5
    80000bf8:	0295e463          	bltu	a1,s1,80000c20 <freerange+0x4a>
    80000bfc:	89ae                	mv	s3,a1
    80000bfe:	7afd                	lui	s5,0xfffff
    80000c00:	6a05                	lui	s4,0x1
    80000c02:	01548933          	add	s2,s1,s5
    inc_ref(p);
    80000c06:	854a                	mv	a0,s2
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	e50080e7          	jalr	-432(ra) # 80000a58 <inc_ref>
    kfree(p);
    80000c10:	854a                	mv	a0,s2
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	f22080e7          	jalr	-222(ra) # 80000b34 <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000c1a:	94d2                	add	s1,s1,s4
    80000c1c:	fe99f3e3          	bgeu	s3,s1,80000c02 <freerange+0x2c>
}
    80000c20:	70e2                	ld	ra,56(sp)
    80000c22:	7442                	ld	s0,48(sp)
    80000c24:	74a2                	ld	s1,40(sp)
    80000c26:	7902                	ld	s2,32(sp)
    80000c28:	69e2                	ld	s3,24(sp)
    80000c2a:	6a42                	ld	s4,16(sp)
    80000c2c:	6aa2                	ld	s5,8(sp)
    80000c2e:	6121                	addi	sp,sp,64
    80000c30:	8082                	ret

0000000080000c32 <kinit>:
{
    80000c32:	1141                	addi	sp,sp,-16
    80000c34:	e406                	sd	ra,8(sp)
    80000c36:	e022                	sd	s0,0(sp)
    80000c38:	0800                	addi	s0,sp,16
   init_ref();
    80000c3a:	00000097          	auipc	ra,0x0
    80000c3e:	dbc080e7          	jalr	-580(ra) # 800009f6 <init_ref>
  initlock(&kmem.lock, "kmem");
    80000c42:	00007597          	auipc	a1,0x7
    80000c46:	44658593          	addi	a1,a1,1094 # 80008088 <digits+0x48>
    80000c4a:	00010517          	auipc	a0,0x10
    80000c4e:	f5e50513          	addi	a0,a0,-162 # 80010ba8 <kmem>
    80000c52:	00000097          	auipc	ra,0x0
    80000c56:	098080e7          	jalr	152(ra) # 80000cea <initlock>
  freerange(end, (void *)PHYSTOP);
    80000c5a:	45c5                	li	a1,17
    80000c5c:	05ee                	slli	a1,a1,0x1b
    80000c5e:	00243517          	auipc	a0,0x243
    80000c62:	97a50513          	addi	a0,a0,-1670 # 802435d8 <end>
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	f70080e7          	jalr	-144(ra) # 80000bd6 <freerange>
}
    80000c6e:	60a2                	ld	ra,8(sp)
    80000c70:	6402                	ld	s0,0(sp)
    80000c72:	0141                	addi	sp,sp,16
    80000c74:	8082                	ret

0000000080000c76 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c80:	00010517          	auipc	a0,0x10
    80000c84:	f2850513          	addi	a0,a0,-216 # 80010ba8 <kmem>
    80000c88:	00000097          	auipc	ra,0x0
    80000c8c:	0f2080e7          	jalr	242(ra) # 80000d7a <acquire>
  r = kmem.freelist;
    80000c90:	00010497          	auipc	s1,0x10
    80000c94:	f304b483          	ld	s1,-208(s1) # 80010bc0 <kmem+0x18>
  if (r)
    80000c98:	c0a1                	beqz	s1,80000cd8 <kalloc+0x62>
    kmem.freelist = r->next;
    80000c9a:	609c                	ld	a5,0(s1)
    80000c9c:	00010717          	auipc	a4,0x10
    80000ca0:	f2f73223          	sd	a5,-220(a4) # 80010bc0 <kmem+0x18>
  release(&kmem.lock);
    80000ca4:	00010517          	auipc	a0,0x10
    80000ca8:	f0450513          	addi	a0,a0,-252 # 80010ba8 <kmem>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	182080e7          	jalr	386(ra) # 80000e2e <release>

  if (r)
  {
    memset((char *)r, 5, PGSIZE);
    80000cb4:	6605                	lui	a2,0x1
    80000cb6:	4595                	li	a1,5
    80000cb8:	8526                	mv	a0,s1
    80000cba:	00000097          	auipc	ra,0x0
    80000cbe:	1bc080e7          	jalr	444(ra) # 80000e76 <memset>
    inc_ref((void*)r);
    80000cc2:	8526                	mv	a0,s1
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	d94080e7          	jalr	-620(ra) # 80000a58 <inc_ref>
  }
     // fill with junk
  return (void *)r;
}
    80000ccc:	8526                	mv	a0,s1
    80000cce:	60e2                	ld	ra,24(sp)
    80000cd0:	6442                	ld	s0,16(sp)
    80000cd2:	64a2                	ld	s1,8(sp)
    80000cd4:	6105                	addi	sp,sp,32
    80000cd6:	8082                	ret
  release(&kmem.lock);
    80000cd8:	00010517          	auipc	a0,0x10
    80000cdc:	ed050513          	addi	a0,a0,-304 # 80010ba8 <kmem>
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	14e080e7          	jalr	334(ra) # 80000e2e <release>
  if (r)
    80000ce8:	b7d5                	j	80000ccc <kalloc+0x56>

0000000080000cea <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cea:	1141                	addi	sp,sp,-16
    80000cec:	e422                	sd	s0,8(sp)
    80000cee:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cf0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cf2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cf6:	00053823          	sd	zero,16(a0)
}
    80000cfa:	6422                	ld	s0,8(sp)
    80000cfc:	0141                	addi	sp,sp,16
    80000cfe:	8082                	ret

0000000080000d00 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d00:	411c                	lw	a5,0(a0)
    80000d02:	e399                	bnez	a5,80000d08 <holding+0x8>
    80000d04:	4501                	li	a0,0
  return r;
}
    80000d06:	8082                	ret
{
    80000d08:	1101                	addi	sp,sp,-32
    80000d0a:	ec06                	sd	ra,24(sp)
    80000d0c:	e822                	sd	s0,16(sp)
    80000d0e:	e426                	sd	s1,8(sp)
    80000d10:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d12:	6904                	ld	s1,16(a0)
    80000d14:	00001097          	auipc	ra,0x1
    80000d18:	e62080e7          	jalr	-414(ra) # 80001b76 <mycpu>
    80000d1c:	40a48533          	sub	a0,s1,a0
    80000d20:	00153513          	seqz	a0,a0
}
    80000d24:	60e2                	ld	ra,24(sp)
    80000d26:	6442                	ld	s0,16(sp)
    80000d28:	64a2                	ld	s1,8(sp)
    80000d2a:	6105                	addi	sp,sp,32
    80000d2c:	8082                	ret

0000000080000d2e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d2e:	1101                	addi	sp,sp,-32
    80000d30:	ec06                	sd	ra,24(sp)
    80000d32:	e822                	sd	s0,16(sp)
    80000d34:	e426                	sd	s1,8(sp)
    80000d36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d38:	100024f3          	csrr	s1,sstatus
    80000d3c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d40:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d42:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d46:	00001097          	auipc	ra,0x1
    80000d4a:	e30080e7          	jalr	-464(ra) # 80001b76 <mycpu>
    80000d4e:	5d3c                	lw	a5,120(a0)
    80000d50:	cf89                	beqz	a5,80000d6a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d52:	00001097          	auipc	ra,0x1
    80000d56:	e24080e7          	jalr	-476(ra) # 80001b76 <mycpu>
    80000d5a:	5d3c                	lw	a5,120(a0)
    80000d5c:	2785                	addiw	a5,a5,1
    80000d5e:	dd3c                	sw	a5,120(a0)
}
    80000d60:	60e2                	ld	ra,24(sp)
    80000d62:	6442                	ld	s0,16(sp)
    80000d64:	64a2                	ld	s1,8(sp)
    80000d66:	6105                	addi	sp,sp,32
    80000d68:	8082                	ret
    mycpu()->intena = old;
    80000d6a:	00001097          	auipc	ra,0x1
    80000d6e:	e0c080e7          	jalr	-500(ra) # 80001b76 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d72:	8085                	srli	s1,s1,0x1
    80000d74:	8885                	andi	s1,s1,1
    80000d76:	dd64                	sw	s1,124(a0)
    80000d78:	bfe9                	j	80000d52 <push_off+0x24>

0000000080000d7a <acquire>:
{
    80000d7a:	1101                	addi	sp,sp,-32
    80000d7c:	ec06                	sd	ra,24(sp)
    80000d7e:	e822                	sd	s0,16(sp)
    80000d80:	e426                	sd	s1,8(sp)
    80000d82:	1000                	addi	s0,sp,32
    80000d84:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	fa8080e7          	jalr	-88(ra) # 80000d2e <push_off>
  if(holding(lk))
    80000d8e:	8526                	mv	a0,s1
    80000d90:	00000097          	auipc	ra,0x0
    80000d94:	f70080e7          	jalr	-144(ra) # 80000d00 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d98:	4705                	li	a4,1
  if(holding(lk))
    80000d9a:	e115                	bnez	a0,80000dbe <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d9c:	87ba                	mv	a5,a4
    80000d9e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000da2:	2781                	sext.w	a5,a5
    80000da4:	ffe5                	bnez	a5,80000d9c <acquire+0x22>
  __sync_synchronize();
    80000da6:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000daa:	00001097          	auipc	ra,0x1
    80000dae:	dcc080e7          	jalr	-564(ra) # 80001b76 <mycpu>
    80000db2:	e888                	sd	a0,16(s1)
}
    80000db4:	60e2                	ld	ra,24(sp)
    80000db6:	6442                	ld	s0,16(sp)
    80000db8:	64a2                	ld	s1,8(sp)
    80000dba:	6105                	addi	sp,sp,32
    80000dbc:	8082                	ret
    panic("acquire");
    80000dbe:	00007517          	auipc	a0,0x7
    80000dc2:	2d250513          	addi	a0,a0,722 # 80008090 <digits+0x50>
    80000dc6:	fffff097          	auipc	ra,0xfffff
    80000dca:	77a080e7          	jalr	1914(ra) # 80000540 <panic>

0000000080000dce <pop_off>:

void
pop_off(void)
{
    80000dce:	1141                	addi	sp,sp,-16
    80000dd0:	e406                	sd	ra,8(sp)
    80000dd2:	e022                	sd	s0,0(sp)
    80000dd4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dd6:	00001097          	auipc	ra,0x1
    80000dda:	da0080e7          	jalr	-608(ra) # 80001b76 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dde:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000de2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000de4:	e78d                	bnez	a5,80000e0e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000de6:	5d3c                	lw	a5,120(a0)
    80000de8:	02f05b63          	blez	a5,80000e1e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dec:	37fd                	addiw	a5,a5,-1
    80000dee:	0007871b          	sext.w	a4,a5
    80000df2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000df4:	eb09                	bnez	a4,80000e06 <pop_off+0x38>
    80000df6:	5d7c                	lw	a5,124(a0)
    80000df8:	c799                	beqz	a5,80000e06 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000dfe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e02:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e06:	60a2                	ld	ra,8(sp)
    80000e08:	6402                	ld	s0,0(sp)
    80000e0a:	0141                	addi	sp,sp,16
    80000e0c:	8082                	ret
    panic("pop_off - interruptible");
    80000e0e:	00007517          	auipc	a0,0x7
    80000e12:	28a50513          	addi	a0,a0,650 # 80008098 <digits+0x58>
    80000e16:	fffff097          	auipc	ra,0xfffff
    80000e1a:	72a080e7          	jalr	1834(ra) # 80000540 <panic>
    panic("pop_off");
    80000e1e:	00007517          	auipc	a0,0x7
    80000e22:	29250513          	addi	a0,a0,658 # 800080b0 <digits+0x70>
    80000e26:	fffff097          	auipc	ra,0xfffff
    80000e2a:	71a080e7          	jalr	1818(ra) # 80000540 <panic>

0000000080000e2e <release>:
{
    80000e2e:	1101                	addi	sp,sp,-32
    80000e30:	ec06                	sd	ra,24(sp)
    80000e32:	e822                	sd	s0,16(sp)
    80000e34:	e426                	sd	s1,8(sp)
    80000e36:	1000                	addi	s0,sp,32
    80000e38:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e3a:	00000097          	auipc	ra,0x0
    80000e3e:	ec6080e7          	jalr	-314(ra) # 80000d00 <holding>
    80000e42:	c115                	beqz	a0,80000e66 <release+0x38>
  lk->cpu = 0;
    80000e44:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e48:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e4c:	0f50000f          	fence	iorw,ow
    80000e50:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e54:	00000097          	auipc	ra,0x0
    80000e58:	f7a080e7          	jalr	-134(ra) # 80000dce <pop_off>
}
    80000e5c:	60e2                	ld	ra,24(sp)
    80000e5e:	6442                	ld	s0,16(sp)
    80000e60:	64a2                	ld	s1,8(sp)
    80000e62:	6105                	addi	sp,sp,32
    80000e64:	8082                	ret
    panic("release");
    80000e66:	00007517          	auipc	a0,0x7
    80000e6a:	25250513          	addi	a0,a0,594 # 800080b8 <digits+0x78>
    80000e6e:	fffff097          	auipc	ra,0xfffff
    80000e72:	6d2080e7          	jalr	1746(ra) # 80000540 <panic>

0000000080000e76 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e76:	1141                	addi	sp,sp,-16
    80000e78:	e422                	sd	s0,8(sp)
    80000e7a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e7c:	ca19                	beqz	a2,80000e92 <memset+0x1c>
    80000e7e:	87aa                	mv	a5,a0
    80000e80:	1602                	slli	a2,a2,0x20
    80000e82:	9201                	srli	a2,a2,0x20
    80000e84:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e88:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e8c:	0785                	addi	a5,a5,1
    80000e8e:	fee79de3          	bne	a5,a4,80000e88 <memset+0x12>
  }
  return dst;
}
    80000e92:	6422                	ld	s0,8(sp)
    80000e94:	0141                	addi	sp,sp,16
    80000e96:	8082                	ret

0000000080000e98 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e98:	1141                	addi	sp,sp,-16
    80000e9a:	e422                	sd	s0,8(sp)
    80000e9c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e9e:	ca05                	beqz	a2,80000ece <memcmp+0x36>
    80000ea0:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000ea4:	1682                	slli	a3,a3,0x20
    80000ea6:	9281                	srli	a3,a3,0x20
    80000ea8:	0685                	addi	a3,a3,1
    80000eaa:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000eac:	00054783          	lbu	a5,0(a0)
    80000eb0:	0005c703          	lbu	a4,0(a1)
    80000eb4:	00e79863          	bne	a5,a4,80000ec4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000eb8:	0505                	addi	a0,a0,1
    80000eba:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ebc:	fed518e3          	bne	a0,a3,80000eac <memcmp+0x14>
  }

  return 0;
    80000ec0:	4501                	li	a0,0
    80000ec2:	a019                	j	80000ec8 <memcmp+0x30>
      return *s1 - *s2;
    80000ec4:	40e7853b          	subw	a0,a5,a4
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret
  return 0;
    80000ece:	4501                	li	a0,0
    80000ed0:	bfe5                	j	80000ec8 <memcmp+0x30>

0000000080000ed2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e422                	sd	s0,8(sp)
    80000ed6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ed8:	c205                	beqz	a2,80000ef8 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000eda:	02a5e263          	bltu	a1,a0,80000efe <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ede:	1602                	slli	a2,a2,0x20
    80000ee0:	9201                	srli	a2,a2,0x20
    80000ee2:	00c587b3          	add	a5,a1,a2
{
    80000ee6:	872a                	mv	a4,a0
      *d++ = *s++;
    80000ee8:	0585                	addi	a1,a1,1
    80000eea:	0705                	addi	a4,a4,1
    80000eec:	fff5c683          	lbu	a3,-1(a1)
    80000ef0:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ef4:	fef59ae3          	bne	a1,a5,80000ee8 <memmove+0x16>

  return dst;
}
    80000ef8:	6422                	ld	s0,8(sp)
    80000efa:	0141                	addi	sp,sp,16
    80000efc:	8082                	ret
  if(s < d && s + n > d){
    80000efe:	02061693          	slli	a3,a2,0x20
    80000f02:	9281                	srli	a3,a3,0x20
    80000f04:	00d58733          	add	a4,a1,a3
    80000f08:	fce57be3          	bgeu	a0,a4,80000ede <memmove+0xc>
    d += n;
    80000f0c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f0e:	fff6079b          	addiw	a5,a2,-1
    80000f12:	1782                	slli	a5,a5,0x20
    80000f14:	9381                	srli	a5,a5,0x20
    80000f16:	fff7c793          	not	a5,a5
    80000f1a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f1c:	177d                	addi	a4,a4,-1
    80000f1e:	16fd                	addi	a3,a3,-1
    80000f20:	00074603          	lbu	a2,0(a4)
    80000f24:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f28:	fee79ae3          	bne	a5,a4,80000f1c <memmove+0x4a>
    80000f2c:	b7f1                	j	80000ef8 <memmove+0x26>

0000000080000f2e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f2e:	1141                	addi	sp,sp,-16
    80000f30:	e406                	sd	ra,8(sp)
    80000f32:	e022                	sd	s0,0(sp)
    80000f34:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	f9c080e7          	jalr	-100(ra) # 80000ed2 <memmove>
}
    80000f3e:	60a2                	ld	ra,8(sp)
    80000f40:	6402                	ld	s0,0(sp)
    80000f42:	0141                	addi	sp,sp,16
    80000f44:	8082                	ret

0000000080000f46 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f46:	1141                	addi	sp,sp,-16
    80000f48:	e422                	sd	s0,8(sp)
    80000f4a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f4c:	ce11                	beqz	a2,80000f68 <strncmp+0x22>
    80000f4e:	00054783          	lbu	a5,0(a0)
    80000f52:	cf89                	beqz	a5,80000f6c <strncmp+0x26>
    80000f54:	0005c703          	lbu	a4,0(a1)
    80000f58:	00f71a63          	bne	a4,a5,80000f6c <strncmp+0x26>
    n--, p++, q++;
    80000f5c:	367d                	addiw	a2,a2,-1
    80000f5e:	0505                	addi	a0,a0,1
    80000f60:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f62:	f675                	bnez	a2,80000f4e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f64:	4501                	li	a0,0
    80000f66:	a809                	j	80000f78 <strncmp+0x32>
    80000f68:	4501                	li	a0,0
    80000f6a:	a039                	j	80000f78 <strncmp+0x32>
  if(n == 0)
    80000f6c:	ca09                	beqz	a2,80000f7e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f6e:	00054503          	lbu	a0,0(a0)
    80000f72:	0005c783          	lbu	a5,0(a1)
    80000f76:	9d1d                	subw	a0,a0,a5
}
    80000f78:	6422                	ld	s0,8(sp)
    80000f7a:	0141                	addi	sp,sp,16
    80000f7c:	8082                	ret
    return 0;
    80000f7e:	4501                	li	a0,0
    80000f80:	bfe5                	j	80000f78 <strncmp+0x32>

0000000080000f82 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f88:	872a                	mv	a4,a0
    80000f8a:	8832                	mv	a6,a2
    80000f8c:	367d                	addiw	a2,a2,-1
    80000f8e:	01005963          	blez	a6,80000fa0 <strncpy+0x1e>
    80000f92:	0705                	addi	a4,a4,1
    80000f94:	0005c783          	lbu	a5,0(a1)
    80000f98:	fef70fa3          	sb	a5,-1(a4)
    80000f9c:	0585                	addi	a1,a1,1
    80000f9e:	f7f5                	bnez	a5,80000f8a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fa0:	86ba                	mv	a3,a4
    80000fa2:	00c05c63          	blez	a2,80000fba <strncpy+0x38>
    *s++ = 0;
    80000fa6:	0685                	addi	a3,a3,1
    80000fa8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fac:	40d707bb          	subw	a5,a4,a3
    80000fb0:	37fd                	addiw	a5,a5,-1
    80000fb2:	010787bb          	addw	a5,a5,a6
    80000fb6:	fef048e3          	bgtz	a5,80000fa6 <strncpy+0x24>
  return os;
}
    80000fba:	6422                	ld	s0,8(sp)
    80000fbc:	0141                	addi	sp,sp,16
    80000fbe:	8082                	ret

0000000080000fc0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fc0:	1141                	addi	sp,sp,-16
    80000fc2:	e422                	sd	s0,8(sp)
    80000fc4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fc6:	02c05363          	blez	a2,80000fec <safestrcpy+0x2c>
    80000fca:	fff6069b          	addiw	a3,a2,-1
    80000fce:	1682                	slli	a3,a3,0x20
    80000fd0:	9281                	srli	a3,a3,0x20
    80000fd2:	96ae                	add	a3,a3,a1
    80000fd4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fd6:	00d58963          	beq	a1,a3,80000fe8 <safestrcpy+0x28>
    80000fda:	0585                	addi	a1,a1,1
    80000fdc:	0785                	addi	a5,a5,1
    80000fde:	fff5c703          	lbu	a4,-1(a1)
    80000fe2:	fee78fa3          	sb	a4,-1(a5)
    80000fe6:	fb65                	bnez	a4,80000fd6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000fe8:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fec:	6422                	ld	s0,8(sp)
    80000fee:	0141                	addi	sp,sp,16
    80000ff0:	8082                	ret

0000000080000ff2 <strlen>:

int
strlen(const char *s)
{
    80000ff2:	1141                	addi	sp,sp,-16
    80000ff4:	e422                	sd	s0,8(sp)
    80000ff6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ff8:	00054783          	lbu	a5,0(a0)
    80000ffc:	cf91                	beqz	a5,80001018 <strlen+0x26>
    80000ffe:	0505                	addi	a0,a0,1
    80001000:	87aa                	mv	a5,a0
    80001002:	4685                	li	a3,1
    80001004:	9e89                	subw	a3,a3,a0
    80001006:	00f6853b          	addw	a0,a3,a5
    8000100a:	0785                	addi	a5,a5,1
    8000100c:	fff7c703          	lbu	a4,-1(a5)
    80001010:	fb7d                	bnez	a4,80001006 <strlen+0x14>
    ;
  return n;
}
    80001012:	6422                	ld	s0,8(sp)
    80001014:	0141                	addi	sp,sp,16
    80001016:	8082                	ret
  for(n = 0; s[n]; n++)
    80001018:	4501                	li	a0,0
    8000101a:	bfe5                	j	80001012 <strlen+0x20>

000000008000101c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    8000101c:	1141                	addi	sp,sp,-16
    8000101e:	e406                	sd	ra,8(sp)
    80001020:	e022                	sd	s0,0(sp)
    80001022:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001024:	00001097          	auipc	ra,0x1
    80001028:	b42080e7          	jalr	-1214(ra) # 80001b66 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000102c:	00008717          	auipc	a4,0x8
    80001030:	8fc70713          	addi	a4,a4,-1796 # 80008928 <started>
  if(cpuid() == 0){
    80001034:	c139                	beqz	a0,8000107a <main+0x5e>
    while(started == 0)
    80001036:	431c                	lw	a5,0(a4)
    80001038:	2781                	sext.w	a5,a5
    8000103a:	dff5                	beqz	a5,80001036 <main+0x1a>
      ;
    __sync_synchronize();
    8000103c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001040:	00001097          	auipc	ra,0x1
    80001044:	b26080e7          	jalr	-1242(ra) # 80001b66 <cpuid>
    80001048:	85aa                	mv	a1,a0
    8000104a:	00007517          	auipc	a0,0x7
    8000104e:	08e50513          	addi	a0,a0,142 # 800080d8 <digits+0x98>
    80001052:	fffff097          	auipc	ra,0xfffff
    80001056:	538080e7          	jalr	1336(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	0d8080e7          	jalr	216(ra) # 80001132 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001062:	00002097          	auipc	ra,0x2
    80001066:	b1c080e7          	jalr	-1252(ra) # 80002b7e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000106a:	00005097          	auipc	ra,0x5
    8000106e:	506080e7          	jalr	1286(ra) # 80006570 <plicinithart>
  }

  scheduler();        
    80001072:	00001097          	auipc	ra,0x1
    80001076:	08c080e7          	jalr	140(ra) # 800020fe <scheduler>
    consoleinit();
    8000107a:	fffff097          	auipc	ra,0xfffff
    8000107e:	3d6080e7          	jalr	982(ra) # 80000450 <consoleinit>
    printfinit();
    80001082:	fffff097          	auipc	ra,0xfffff
    80001086:	6e8080e7          	jalr	1768(ra) # 8000076a <printfinit>
    printf("\n");
    8000108a:	00007517          	auipc	a0,0x7
    8000108e:	05e50513          	addi	a0,a0,94 # 800080e8 <digits+0xa8>
    80001092:	fffff097          	auipc	ra,0xfffff
    80001096:	4f8080e7          	jalr	1272(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    8000109a:	00007517          	auipc	a0,0x7
    8000109e:	02650513          	addi	a0,a0,38 # 800080c0 <digits+0x80>
    800010a2:	fffff097          	auipc	ra,0xfffff
    800010a6:	4e8080e7          	jalr	1256(ra) # 8000058a <printf>
    printf("\n");
    800010aa:	00007517          	auipc	a0,0x7
    800010ae:	03e50513          	addi	a0,a0,62 # 800080e8 <digits+0xa8>
    800010b2:	fffff097          	auipc	ra,0xfffff
    800010b6:	4d8080e7          	jalr	1240(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    800010ba:	00000097          	auipc	ra,0x0
    800010be:	b78080e7          	jalr	-1160(ra) # 80000c32 <kinit>
    kvminit();       // create kernel page table
    800010c2:	00000097          	auipc	ra,0x0
    800010c6:	326080e7          	jalr	806(ra) # 800013e8 <kvminit>
    kvminithart();   // turn on paging
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	068080e7          	jalr	104(ra) # 80001132 <kvminithart>
    procinit();      // process table
    800010d2:	00001097          	auipc	ra,0x1
    800010d6:	9e0080e7          	jalr	-1568(ra) # 80001ab2 <procinit>
    trapinit();      // trap vectors
    800010da:	00002097          	auipc	ra,0x2
    800010de:	a7c080e7          	jalr	-1412(ra) # 80002b56 <trapinit>
    trapinithart();  // install kernel trap vector
    800010e2:	00002097          	auipc	ra,0x2
    800010e6:	a9c080e7          	jalr	-1380(ra) # 80002b7e <trapinithart>
    plicinit();      // set up interrupt controller
    800010ea:	00005097          	auipc	ra,0x5
    800010ee:	470080e7          	jalr	1136(ra) # 8000655a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010f2:	00005097          	auipc	ra,0x5
    800010f6:	47e080e7          	jalr	1150(ra) # 80006570 <plicinithart>
    binit();         // buffer cache
    800010fa:	00002097          	auipc	ra,0x2
    800010fe:	61a080e7          	jalr	1562(ra) # 80003714 <binit>
    iinit();         // inode table
    80001102:	00003097          	auipc	ra,0x3
    80001106:	cba080e7          	jalr	-838(ra) # 80003dbc <iinit>
    fileinit();      // file table
    8000110a:	00004097          	auipc	ra,0x4
    8000110e:	c60080e7          	jalr	-928(ra) # 80004d6a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001112:	00005097          	auipc	ra,0x5
    80001116:	566080e7          	jalr	1382(ra) # 80006678 <virtio_disk_init>
    userinit();      // first user process
    8000111a:	00001097          	auipc	ra,0x1
    8000111e:	dc6080e7          	jalr	-570(ra) # 80001ee0 <userinit>
    __sync_synchronize();
    80001122:	0ff0000f          	fence
    started = 1;
    80001126:	4785                	li	a5,1
    80001128:	00008717          	auipc	a4,0x8
    8000112c:	80f72023          	sw	a5,-2048(a4) # 80008928 <started>
    80001130:	b789                	j	80001072 <main+0x56>

0000000080001132 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001132:	1141                	addi	sp,sp,-16
    80001134:	e422                	sd	s0,8(sp)
    80001136:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001138:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000113c:	00007797          	auipc	a5,0x7
    80001140:	7f47b783          	ld	a5,2036(a5) # 80008930 <kernel_pagetable>
    80001144:	83b1                	srli	a5,a5,0xc
    80001146:	577d                	li	a4,-1
    80001148:	177e                	slli	a4,a4,0x3f
    8000114a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000114c:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001150:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001154:	6422                	ld	s0,8(sp)
    80001156:	0141                	addi	sp,sp,16
    80001158:	8082                	ret

000000008000115a <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000115a:	7139                	addi	sp,sp,-64
    8000115c:	fc06                	sd	ra,56(sp)
    8000115e:	f822                	sd	s0,48(sp)
    80001160:	f426                	sd	s1,40(sp)
    80001162:	f04a                	sd	s2,32(sp)
    80001164:	ec4e                	sd	s3,24(sp)
    80001166:	e852                	sd	s4,16(sp)
    80001168:	e456                	sd	s5,8(sp)
    8000116a:	e05a                	sd	s6,0(sp)
    8000116c:	0080                	addi	s0,sp,64
    8000116e:	84aa                	mv	s1,a0
    80001170:	89ae                	mv	s3,a1
    80001172:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001174:	57fd                	li	a5,-1
    80001176:	83e9                	srli	a5,a5,0x1a
    80001178:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000117a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000117c:	04b7f263          	bgeu	a5,a1,800011c0 <walk+0x66>
    panic("walk");
    80001180:	00007517          	auipc	a0,0x7
    80001184:	f7050513          	addi	a0,a0,-144 # 800080f0 <digits+0xb0>
    80001188:	fffff097          	auipc	ra,0xfffff
    8000118c:	3b8080e7          	jalr	952(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001190:	060a8663          	beqz	s5,800011fc <walk+0xa2>
    80001194:	00000097          	auipc	ra,0x0
    80001198:	ae2080e7          	jalr	-1310(ra) # 80000c76 <kalloc>
    8000119c:	84aa                	mv	s1,a0
    8000119e:	c529                	beqz	a0,800011e8 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	cd2080e7          	jalr	-814(ra) # 80000e76 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011ac:	00c4d793          	srli	a5,s1,0xc
    800011b0:	07aa                	slli	a5,a5,0xa
    800011b2:	0017e793          	ori	a5,a5,1
    800011b6:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011ba:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    800011bc:	036a0063          	beq	s4,s6,800011dc <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011c0:	0149d933          	srl	s2,s3,s4
    800011c4:	1ff97913          	andi	s2,s2,511
    800011c8:	090e                	slli	s2,s2,0x3
    800011ca:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011cc:	00093483          	ld	s1,0(s2)
    800011d0:	0014f793          	andi	a5,s1,1
    800011d4:	dfd5                	beqz	a5,80001190 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011d6:	80a9                	srli	s1,s1,0xa
    800011d8:	04b2                	slli	s1,s1,0xc
    800011da:	b7c5                	j	800011ba <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011dc:	00c9d513          	srli	a0,s3,0xc
    800011e0:	1ff57513          	andi	a0,a0,511
    800011e4:	050e                	slli	a0,a0,0x3
    800011e6:	9526                	add	a0,a0,s1
}
    800011e8:	70e2                	ld	ra,56(sp)
    800011ea:	7442                	ld	s0,48(sp)
    800011ec:	74a2                	ld	s1,40(sp)
    800011ee:	7902                	ld	s2,32(sp)
    800011f0:	69e2                	ld	s3,24(sp)
    800011f2:	6a42                	ld	s4,16(sp)
    800011f4:	6aa2                	ld	s5,8(sp)
    800011f6:	6b02                	ld	s6,0(sp)
    800011f8:	6121                	addi	sp,sp,64
    800011fa:	8082                	ret
        return 0;
    800011fc:	4501                	li	a0,0
    800011fe:	b7ed                	j	800011e8 <walk+0x8e>

0000000080001200 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001200:	57fd                	li	a5,-1
    80001202:	83e9                	srli	a5,a5,0x1a
    80001204:	00b7f463          	bgeu	a5,a1,8000120c <walkaddr+0xc>
    return 0;
    80001208:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000120a:	8082                	ret
{
    8000120c:	1141                	addi	sp,sp,-16
    8000120e:	e406                	sd	ra,8(sp)
    80001210:	e022                	sd	s0,0(sp)
    80001212:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001214:	4601                	li	a2,0
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f44080e7          	jalr	-188(ra) # 8000115a <walk>
  if(pte == 0)
    8000121e:	c105                	beqz	a0,8000123e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001220:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001222:	0117f693          	andi	a3,a5,17
    80001226:	4745                	li	a4,17
    return 0;
    80001228:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000122a:	00e68663          	beq	a3,a4,80001236 <walkaddr+0x36>
}
    8000122e:	60a2                	ld	ra,8(sp)
    80001230:	6402                	ld	s0,0(sp)
    80001232:	0141                	addi	sp,sp,16
    80001234:	8082                	ret
  pa = PTE2PA(*pte);
    80001236:	83a9                	srli	a5,a5,0xa
    80001238:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000123c:	bfcd                	j	8000122e <walkaddr+0x2e>
    return 0;
    8000123e:	4501                	li	a0,0
    80001240:	b7fd                	j	8000122e <walkaddr+0x2e>

0000000080001242 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001258:	c639                	beqz	a2,800012a6 <mappages+0x64>
    8000125a:	8aaa                	mv	s5,a0
    8000125c:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000125e:	777d                	lui	a4,0xfffff
    80001260:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001264:	fff58993          	addi	s3,a1,-1
    80001268:	99b2                	add	s3,s3,a2
    8000126a:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000126e:	893e                	mv	s2,a5
    80001270:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001274:	6b85                	lui	s7,0x1
    80001276:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000127a:	4605                	li	a2,1
    8000127c:	85ca                	mv	a1,s2
    8000127e:	8556                	mv	a0,s5
    80001280:	00000097          	auipc	ra,0x0
    80001284:	eda080e7          	jalr	-294(ra) # 8000115a <walk>
    80001288:	cd1d                	beqz	a0,800012c6 <mappages+0x84>
    if(*pte & PTE_V)
    8000128a:	611c                	ld	a5,0(a0)
    8000128c:	8b85                	andi	a5,a5,1
    8000128e:	e785                	bnez	a5,800012b6 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001290:	80b1                	srli	s1,s1,0xc
    80001292:	04aa                	slli	s1,s1,0xa
    80001294:	0164e4b3          	or	s1,s1,s6
    80001298:	0014e493          	ori	s1,s1,1
    8000129c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000129e:	05390063          	beq	s2,s3,800012de <mappages+0x9c>
    a += PGSIZE;
    800012a2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012a4:	bfc9                	j	80001276 <mappages+0x34>
    panic("mappages: size");
    800012a6:	00007517          	auipc	a0,0x7
    800012aa:	e5250513          	addi	a0,a0,-430 # 800080f8 <digits+0xb8>
    800012ae:	fffff097          	auipc	ra,0xfffff
    800012b2:	292080e7          	jalr	658(ra) # 80000540 <panic>
      panic("mappages: remap");
    800012b6:	00007517          	auipc	a0,0x7
    800012ba:	e5250513          	addi	a0,a0,-430 # 80008108 <digits+0xc8>
    800012be:	fffff097          	auipc	ra,0xfffff
    800012c2:	282080e7          	jalr	642(ra) # 80000540 <panic>
      return -1;
    800012c6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012c8:	60a6                	ld	ra,72(sp)
    800012ca:	6406                	ld	s0,64(sp)
    800012cc:	74e2                	ld	s1,56(sp)
    800012ce:	7942                	ld	s2,48(sp)
    800012d0:	79a2                	ld	s3,40(sp)
    800012d2:	7a02                	ld	s4,32(sp)
    800012d4:	6ae2                	ld	s5,24(sp)
    800012d6:	6b42                	ld	s6,16(sp)
    800012d8:	6ba2                	ld	s7,8(sp)
    800012da:	6161                	addi	sp,sp,80
    800012dc:	8082                	ret
  return 0;
    800012de:	4501                	li	a0,0
    800012e0:	b7e5                	j	800012c8 <mappages+0x86>

00000000800012e2 <kvmmap>:
{
    800012e2:	1141                	addi	sp,sp,-16
    800012e4:	e406                	sd	ra,8(sp)
    800012e6:	e022                	sd	s0,0(sp)
    800012e8:	0800                	addi	s0,sp,16
    800012ea:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012ec:	86b2                	mv	a3,a2
    800012ee:	863e                	mv	a2,a5
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	f52080e7          	jalr	-174(ra) # 80001242 <mappages>
    800012f8:	e509                	bnez	a0,80001302 <kvmmap+0x20>
}
    800012fa:	60a2                	ld	ra,8(sp)
    800012fc:	6402                	ld	s0,0(sp)
    800012fe:	0141                	addi	sp,sp,16
    80001300:	8082                	ret
    panic("kvmmap");
    80001302:	00007517          	auipc	a0,0x7
    80001306:	e1650513          	addi	a0,a0,-490 # 80008118 <digits+0xd8>
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	236080e7          	jalr	566(ra) # 80000540 <panic>

0000000080001312 <kvmmake>:
{
    80001312:	1101                	addi	sp,sp,-32
    80001314:	ec06                	sd	ra,24(sp)
    80001316:	e822                	sd	s0,16(sp)
    80001318:	e426                	sd	s1,8(sp)
    8000131a:	e04a                	sd	s2,0(sp)
    8000131c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	958080e7          	jalr	-1704(ra) # 80000c76 <kalloc>
    80001326:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001328:	6605                	lui	a2,0x1
    8000132a:	4581                	li	a1,0
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	b4a080e7          	jalr	-1206(ra) # 80000e76 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001334:	4719                	li	a4,6
    80001336:	6685                	lui	a3,0x1
    80001338:	10000637          	lui	a2,0x10000
    8000133c:	100005b7          	lui	a1,0x10000
    80001340:	8526                	mv	a0,s1
    80001342:	00000097          	auipc	ra,0x0
    80001346:	fa0080e7          	jalr	-96(ra) # 800012e2 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000134a:	4719                	li	a4,6
    8000134c:	6685                	lui	a3,0x1
    8000134e:	10001637          	lui	a2,0x10001
    80001352:	100015b7          	lui	a1,0x10001
    80001356:	8526                	mv	a0,s1
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	f8a080e7          	jalr	-118(ra) # 800012e2 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001360:	4719                	li	a4,6
    80001362:	004006b7          	lui	a3,0x400
    80001366:	0c000637          	lui	a2,0xc000
    8000136a:	0c0005b7          	lui	a1,0xc000
    8000136e:	8526                	mv	a0,s1
    80001370:	00000097          	auipc	ra,0x0
    80001374:	f72080e7          	jalr	-142(ra) # 800012e2 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001378:	00007917          	auipc	s2,0x7
    8000137c:	c8890913          	addi	s2,s2,-888 # 80008000 <etext>
    80001380:	4729                	li	a4,10
    80001382:	80007697          	auipc	a3,0x80007
    80001386:	c7e68693          	addi	a3,a3,-898 # 8000 <_entry-0x7fff8000>
    8000138a:	4605                	li	a2,1
    8000138c:	067e                	slli	a2,a2,0x1f
    8000138e:	85b2                	mv	a1,a2
    80001390:	8526                	mv	a0,s1
    80001392:	00000097          	auipc	ra,0x0
    80001396:	f50080e7          	jalr	-176(ra) # 800012e2 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000139a:	4719                	li	a4,6
    8000139c:	46c5                	li	a3,17
    8000139e:	06ee                	slli	a3,a3,0x1b
    800013a0:	412686b3          	sub	a3,a3,s2
    800013a4:	864a                	mv	a2,s2
    800013a6:	85ca                	mv	a1,s2
    800013a8:	8526                	mv	a0,s1
    800013aa:	00000097          	auipc	ra,0x0
    800013ae:	f38080e7          	jalr	-200(ra) # 800012e2 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013b2:	4729                	li	a4,10
    800013b4:	6685                	lui	a3,0x1
    800013b6:	00006617          	auipc	a2,0x6
    800013ba:	c4a60613          	addi	a2,a2,-950 # 80007000 <_trampoline>
    800013be:	040005b7          	lui	a1,0x4000
    800013c2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013c4:	05b2                	slli	a1,a1,0xc
    800013c6:	8526                	mv	a0,s1
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	f1a080e7          	jalr	-230(ra) # 800012e2 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013d0:	8526                	mv	a0,s1
    800013d2:	00000097          	auipc	ra,0x0
    800013d6:	64a080e7          	jalr	1610(ra) # 80001a1c <proc_mapstacks>
}
    800013da:	8526                	mv	a0,s1
    800013dc:	60e2                	ld	ra,24(sp)
    800013de:	6442                	ld	s0,16(sp)
    800013e0:	64a2                	ld	s1,8(sp)
    800013e2:	6902                	ld	s2,0(sp)
    800013e4:	6105                	addi	sp,sp,32
    800013e6:	8082                	ret

00000000800013e8 <kvminit>:
{
    800013e8:	1141                	addi	sp,sp,-16
    800013ea:	e406                	sd	ra,8(sp)
    800013ec:	e022                	sd	s0,0(sp)
    800013ee:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013f0:	00000097          	auipc	ra,0x0
    800013f4:	f22080e7          	jalr	-222(ra) # 80001312 <kvmmake>
    800013f8:	00007797          	auipc	a5,0x7
    800013fc:	52a7bc23          	sd	a0,1336(a5) # 80008930 <kernel_pagetable>
}
    80001400:	60a2                	ld	ra,8(sp)
    80001402:	6402                	ld	s0,0(sp)
    80001404:	0141                	addi	sp,sp,16
    80001406:	8082                	ret

0000000080001408 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001408:	715d                	addi	sp,sp,-80
    8000140a:	e486                	sd	ra,72(sp)
    8000140c:	e0a2                	sd	s0,64(sp)
    8000140e:	fc26                	sd	s1,56(sp)
    80001410:	f84a                	sd	s2,48(sp)
    80001412:	f44e                	sd	s3,40(sp)
    80001414:	f052                	sd	s4,32(sp)
    80001416:	ec56                	sd	s5,24(sp)
    80001418:	e85a                	sd	s6,16(sp)
    8000141a:	e45e                	sd	s7,8(sp)
    8000141c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000141e:	03459793          	slli	a5,a1,0x34
    80001422:	e795                	bnez	a5,8000144e <uvmunmap+0x46>
    80001424:	8a2a                	mv	s4,a0
    80001426:	892e                	mv	s2,a1
    80001428:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000142a:	0632                	slli	a2,a2,0xc
    8000142c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001430:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001432:	6b05                	lui	s6,0x1
    80001434:	0735e263          	bltu	a1,s3,80001498 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001438:	60a6                	ld	ra,72(sp)
    8000143a:	6406                	ld	s0,64(sp)
    8000143c:	74e2                	ld	s1,56(sp)
    8000143e:	7942                	ld	s2,48(sp)
    80001440:	79a2                	ld	s3,40(sp)
    80001442:	7a02                	ld	s4,32(sp)
    80001444:	6ae2                	ld	s5,24(sp)
    80001446:	6b42                	ld	s6,16(sp)
    80001448:	6ba2                	ld	s7,8(sp)
    8000144a:	6161                	addi	sp,sp,80
    8000144c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000144e:	00007517          	auipc	a0,0x7
    80001452:	cd250513          	addi	a0,a0,-814 # 80008120 <digits+0xe0>
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	0ea080e7          	jalr	234(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    8000145e:	00007517          	auipc	a0,0x7
    80001462:	cda50513          	addi	a0,a0,-806 # 80008138 <digits+0xf8>
    80001466:	fffff097          	auipc	ra,0xfffff
    8000146a:	0da080e7          	jalr	218(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    8000146e:	00007517          	auipc	a0,0x7
    80001472:	cda50513          	addi	a0,a0,-806 # 80008148 <digits+0x108>
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	0ca080e7          	jalr	202(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    8000147e:	00007517          	auipc	a0,0x7
    80001482:	ce250513          	addi	a0,a0,-798 # 80008160 <digits+0x120>
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	0ba080e7          	jalr	186(ra) # 80000540 <panic>
    *pte = 0;
    8000148e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001492:	995a                	add	s2,s2,s6
    80001494:	fb3972e3          	bgeu	s2,s3,80001438 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001498:	4601                	li	a2,0
    8000149a:	85ca                	mv	a1,s2
    8000149c:	8552                	mv	a0,s4
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	cbc080e7          	jalr	-836(ra) # 8000115a <walk>
    800014a6:	84aa                	mv	s1,a0
    800014a8:	d95d                	beqz	a0,8000145e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014aa:	6108                	ld	a0,0(a0)
    800014ac:	00157793          	andi	a5,a0,1
    800014b0:	dfdd                	beqz	a5,8000146e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014b2:	3ff57793          	andi	a5,a0,1023
    800014b6:	fd7784e3          	beq	a5,s7,8000147e <uvmunmap+0x76>
    if(do_free){
    800014ba:	fc0a8ae3          	beqz	s5,8000148e <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014be:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014c0:	0532                	slli	a0,a0,0xc
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	672080e7          	jalr	1650(ra) # 80000b34 <kfree>
    800014ca:	b7d1                	j	8000148e <uvmunmap+0x86>

00000000800014cc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014cc:	1101                	addi	sp,sp,-32
    800014ce:	ec06                	sd	ra,24(sp)
    800014d0:	e822                	sd	s0,16(sp)
    800014d2:	e426                	sd	s1,8(sp)
    800014d4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014d6:	fffff097          	auipc	ra,0xfffff
    800014da:	7a0080e7          	jalr	1952(ra) # 80000c76 <kalloc>
    800014de:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014e0:	c519                	beqz	a0,800014ee <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014e2:	6605                	lui	a2,0x1
    800014e4:	4581                	li	a1,0
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	990080e7          	jalr	-1648(ra) # 80000e76 <memset>
  return pagetable;
}
    800014ee:	8526                	mv	a0,s1
    800014f0:	60e2                	ld	ra,24(sp)
    800014f2:	6442                	ld	s0,16(sp)
    800014f4:	64a2                	ld	s1,8(sp)
    800014f6:	6105                	addi	sp,sp,32
    800014f8:	8082                	ret

00000000800014fa <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014fa:	7179                	addi	sp,sp,-48
    800014fc:	f406                	sd	ra,40(sp)
    800014fe:	f022                	sd	s0,32(sp)
    80001500:	ec26                	sd	s1,24(sp)
    80001502:	e84a                	sd	s2,16(sp)
    80001504:	e44e                	sd	s3,8(sp)
    80001506:	e052                	sd	s4,0(sp)
    80001508:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000150a:	6785                	lui	a5,0x1
    8000150c:	04f67863          	bgeu	a2,a5,8000155c <uvmfirst+0x62>
    80001510:	8a2a                	mv	s4,a0
    80001512:	89ae                	mv	s3,a1
    80001514:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	760080e7          	jalr	1888(ra) # 80000c76 <kalloc>
    8000151e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001520:	6605                	lui	a2,0x1
    80001522:	4581                	li	a1,0
    80001524:	00000097          	auipc	ra,0x0
    80001528:	952080e7          	jalr	-1710(ra) # 80000e76 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000152c:	4779                	li	a4,30
    8000152e:	86ca                	mv	a3,s2
    80001530:	6605                	lui	a2,0x1
    80001532:	4581                	li	a1,0
    80001534:	8552                	mv	a0,s4
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	d0c080e7          	jalr	-756(ra) # 80001242 <mappages>
  memmove(mem, src, sz);
    8000153e:	8626                	mv	a2,s1
    80001540:	85ce                	mv	a1,s3
    80001542:	854a                	mv	a0,s2
    80001544:	00000097          	auipc	ra,0x0
    80001548:	98e080e7          	jalr	-1650(ra) # 80000ed2 <memmove>
}
    8000154c:	70a2                	ld	ra,40(sp)
    8000154e:	7402                	ld	s0,32(sp)
    80001550:	64e2                	ld	s1,24(sp)
    80001552:	6942                	ld	s2,16(sp)
    80001554:	69a2                	ld	s3,8(sp)
    80001556:	6a02                	ld	s4,0(sp)
    80001558:	6145                	addi	sp,sp,48
    8000155a:	8082                	ret
    panic("uvmfirst: more than a page");
    8000155c:	00007517          	auipc	a0,0x7
    80001560:	c1c50513          	addi	a0,a0,-996 # 80008178 <digits+0x138>
    80001564:	fffff097          	auipc	ra,0xfffff
    80001568:	fdc080e7          	jalr	-36(ra) # 80000540 <panic>

000000008000156c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000156c:	1101                	addi	sp,sp,-32
    8000156e:	ec06                	sd	ra,24(sp)
    80001570:	e822                	sd	s0,16(sp)
    80001572:	e426                	sd	s1,8(sp)
    80001574:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001576:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001578:	00b67d63          	bgeu	a2,a1,80001592 <uvmdealloc+0x26>
    8000157c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000157e:	6785                	lui	a5,0x1
    80001580:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001582:	00f60733          	add	a4,a2,a5
    80001586:	76fd                	lui	a3,0xfffff
    80001588:	8f75                	and	a4,a4,a3
    8000158a:	97ae                	add	a5,a5,a1
    8000158c:	8ff5                	and	a5,a5,a3
    8000158e:	00f76863          	bltu	a4,a5,8000159e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001592:	8526                	mv	a0,s1
    80001594:	60e2                	ld	ra,24(sp)
    80001596:	6442                	ld	s0,16(sp)
    80001598:	64a2                	ld	s1,8(sp)
    8000159a:	6105                	addi	sp,sp,32
    8000159c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000159e:	8f99                	sub	a5,a5,a4
    800015a0:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015a2:	4685                	li	a3,1
    800015a4:	0007861b          	sext.w	a2,a5
    800015a8:	85ba                	mv	a1,a4
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	e5e080e7          	jalr	-418(ra) # 80001408 <uvmunmap>
    800015b2:	b7c5                	j	80001592 <uvmdealloc+0x26>

00000000800015b4 <uvmalloc>:
  if(newsz < oldsz)
    800015b4:	0ab66563          	bltu	a2,a1,8000165e <uvmalloc+0xaa>
{
    800015b8:	7139                	addi	sp,sp,-64
    800015ba:	fc06                	sd	ra,56(sp)
    800015bc:	f822                	sd	s0,48(sp)
    800015be:	f426                	sd	s1,40(sp)
    800015c0:	f04a                	sd	s2,32(sp)
    800015c2:	ec4e                	sd	s3,24(sp)
    800015c4:	e852                	sd	s4,16(sp)
    800015c6:	e456                	sd	s5,8(sp)
    800015c8:	e05a                	sd	s6,0(sp)
    800015ca:	0080                	addi	s0,sp,64
    800015cc:	8aaa                	mv	s5,a0
    800015ce:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015d0:	6785                	lui	a5,0x1
    800015d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015d4:	95be                	add	a1,a1,a5
    800015d6:	77fd                	lui	a5,0xfffff
    800015d8:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015dc:	08c9f363          	bgeu	s3,a2,80001662 <uvmalloc+0xae>
    800015e0:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015e2:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	690080e7          	jalr	1680(ra) # 80000c76 <kalloc>
    800015ee:	84aa                	mv	s1,a0
    if(mem == 0){
    800015f0:	c51d                	beqz	a0,8000161e <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015f2:	6605                	lui	a2,0x1
    800015f4:	4581                	li	a1,0
    800015f6:	00000097          	auipc	ra,0x0
    800015fa:	880080e7          	jalr	-1920(ra) # 80000e76 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015fe:	875a                	mv	a4,s6
    80001600:	86a6                	mv	a3,s1
    80001602:	6605                	lui	a2,0x1
    80001604:	85ca                	mv	a1,s2
    80001606:	8556                	mv	a0,s5
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	c3a080e7          	jalr	-966(ra) # 80001242 <mappages>
    80001610:	e90d                	bnez	a0,80001642 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001612:	6785                	lui	a5,0x1
    80001614:	993e                	add	s2,s2,a5
    80001616:	fd4968e3          	bltu	s2,s4,800015e6 <uvmalloc+0x32>
  return newsz;
    8000161a:	8552                	mv	a0,s4
    8000161c:	a809                	j	8000162e <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000161e:	864e                	mv	a2,s3
    80001620:	85ca                	mv	a1,s2
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	f48080e7          	jalr	-184(ra) # 8000156c <uvmdealloc>
      return 0;
    8000162c:	4501                	li	a0,0
}
    8000162e:	70e2                	ld	ra,56(sp)
    80001630:	7442                	ld	s0,48(sp)
    80001632:	74a2                	ld	s1,40(sp)
    80001634:	7902                	ld	s2,32(sp)
    80001636:	69e2                	ld	s3,24(sp)
    80001638:	6a42                	ld	s4,16(sp)
    8000163a:	6aa2                	ld	s5,8(sp)
    8000163c:	6b02                	ld	s6,0(sp)
    8000163e:	6121                	addi	sp,sp,64
    80001640:	8082                	ret
      kfree(mem);
    80001642:	8526                	mv	a0,s1
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	4f0080e7          	jalr	1264(ra) # 80000b34 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000164c:	864e                	mv	a2,s3
    8000164e:	85ca                	mv	a1,s2
    80001650:	8556                	mv	a0,s5
    80001652:	00000097          	auipc	ra,0x0
    80001656:	f1a080e7          	jalr	-230(ra) # 8000156c <uvmdealloc>
      return 0;
    8000165a:	4501                	li	a0,0
    8000165c:	bfc9                	j	8000162e <uvmalloc+0x7a>
    return oldsz;
    8000165e:	852e                	mv	a0,a1
}
    80001660:	8082                	ret
  return newsz;
    80001662:	8532                	mv	a0,a2
    80001664:	b7e9                	j	8000162e <uvmalloc+0x7a>

0000000080001666 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001666:	7179                	addi	sp,sp,-48
    80001668:	f406                	sd	ra,40(sp)
    8000166a:	f022                	sd	s0,32(sp)
    8000166c:	ec26                	sd	s1,24(sp)
    8000166e:	e84a                	sd	s2,16(sp)
    80001670:	e44e                	sd	s3,8(sp)
    80001672:	e052                	sd	s4,0(sp)
    80001674:	1800                	addi	s0,sp,48
    80001676:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001678:	84aa                	mv	s1,a0
    8000167a:	6905                	lui	s2,0x1
    8000167c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000167e:	4985                	li	s3,1
    80001680:	a829                	j	8000169a <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001682:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001684:	00c79513          	slli	a0,a5,0xc
    80001688:	00000097          	auipc	ra,0x0
    8000168c:	fde080e7          	jalr	-34(ra) # 80001666 <freewalk>
      pagetable[i] = 0;
    80001690:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001694:	04a1                	addi	s1,s1,8
    80001696:	03248163          	beq	s1,s2,800016b8 <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000169a:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000169c:	00f7f713          	andi	a4,a5,15
    800016a0:	ff3701e3          	beq	a4,s3,80001682 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016a4:	8b85                	andi	a5,a5,1
    800016a6:	d7fd                	beqz	a5,80001694 <freewalk+0x2e>
      panic("freewalk: leaf");
    800016a8:	00007517          	auipc	a0,0x7
    800016ac:	af050513          	addi	a0,a0,-1296 # 80008198 <digits+0x158>
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	e90080e7          	jalr	-368(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    800016b8:	8552                	mv	a0,s4
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	47a080e7          	jalr	1146(ra) # 80000b34 <kfree>
}
    800016c2:	70a2                	ld	ra,40(sp)
    800016c4:	7402                	ld	s0,32(sp)
    800016c6:	64e2                	ld	s1,24(sp)
    800016c8:	6942                	ld	s2,16(sp)
    800016ca:	69a2                	ld	s3,8(sp)
    800016cc:	6a02                	ld	s4,0(sp)
    800016ce:	6145                	addi	sp,sp,48
    800016d0:	8082                	ret

00000000800016d2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016d2:	1101                	addi	sp,sp,-32
    800016d4:	ec06                	sd	ra,24(sp)
    800016d6:	e822                	sd	s0,16(sp)
    800016d8:	e426                	sd	s1,8(sp)
    800016da:	1000                	addi	s0,sp,32
    800016dc:	84aa                	mv	s1,a0
  if(sz > 0)
    800016de:	e999                	bnez	a1,800016f4 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016e0:	8526                	mv	a0,s1
    800016e2:	00000097          	auipc	ra,0x0
    800016e6:	f84080e7          	jalr	-124(ra) # 80001666 <freewalk>
}
    800016ea:	60e2                	ld	ra,24(sp)
    800016ec:	6442                	ld	s0,16(sp)
    800016ee:	64a2                	ld	s1,8(sp)
    800016f0:	6105                	addi	sp,sp,32
    800016f2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016f4:	6785                	lui	a5,0x1
    800016f6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016f8:	95be                	add	a1,a1,a5
    800016fa:	4685                	li	a3,1
    800016fc:	00c5d613          	srli	a2,a1,0xc
    80001700:	4581                	li	a1,0
    80001702:	00000097          	auipc	ra,0x0
    80001706:	d06080e7          	jalr	-762(ra) # 80001408 <uvmunmap>
    8000170a:	bfd9                	j	800016e0 <uvmfree+0xe>

000000008000170c <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    8000170c:	715d                	addi	sp,sp,-80
    8000170e:	e486                	sd	ra,72(sp)
    80001710:	e0a2                	sd	s0,64(sp)
    80001712:	fc26                	sd	s1,56(sp)
    80001714:	f84a                	sd	s2,48(sp)
    80001716:	f44e                	sd	s3,40(sp)
    80001718:	f052                	sd	s4,32(sp)
    8000171a:	ec56                	sd	s5,24(sp)
    8000171c:	e85a                	sd	s6,16(sp)
    8000171e:	e45e                	sd	s7,8(sp)
    80001720:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80001722:	c269                	beqz	a2,800017e4 <uvmcopy+0xd8>
    80001724:	8aaa                	mv	s5,a0
    80001726:	8a2e                	mv	s4,a1
    80001728:	89b2                	mv	s3,a2
    8000172a:	4481                	li	s1,0
    #ifdef COW
    if(flags & PTE_W)
    {
      flags |= PTE_COW;
      flags = flags & (~PTE_W);
      *pte= PA2PTE(PTE2PA(*pte)) | flags;
    8000172c:	7b7d                	lui	s6,0xfffff
    8000172e:	002b5b13          	srli	s6,s6,0x2
    80001732:	a8a1                	j	8000178a <uvmcopy+0x7e>
      panic("uvmcopy: pte should exist");
    80001734:	00007517          	auipc	a0,0x7
    80001738:	a7450513          	addi	a0,a0,-1420 # 800081a8 <digits+0x168>
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	e04080e7          	jalr	-508(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001744:	00007517          	auipc	a0,0x7
    80001748:	a8450513          	addi	a0,a0,-1404 # 800081c8 <digits+0x188>
    8000174c:	fffff097          	auipc	ra,0xfffff
    80001750:	df4080e7          	jalr	-524(ra) # 80000540 <panic>
      flags = flags & (~PTE_W);
    80001754:	3fb77693          	andi	a3,a4,1019
    80001758:	1006e713          	ori	a4,a3,256
      *pte= PA2PTE(PTE2PA(*pte)) | flags;
    8000175c:	0167f7b3          	and	a5,a5,s6
    80001760:	8fd9                	or	a5,a5,a4
    80001762:	e11c                	sd	a5,0(a0)
    }
    #endif

    if(mappages(new,i,PGSIZE,pa,flags)!=0)
    80001764:	86ca                	mv	a3,s2
    80001766:	6605                	lui	a2,0x1
    80001768:	85a6                	mv	a1,s1
    8000176a:	8552                	mv	a0,s4
    8000176c:	00000097          	auipc	ra,0x0
    80001770:	ad6080e7          	jalr	-1322(ra) # 80001242 <mappages>
    80001774:	8baa                	mv	s7,a0
    80001776:	e129                	bnez	a0,800017b8 <uvmcopy+0xac>
    {
      goto err;
    }
    inc_ref((void*)pa);
    80001778:	854a                	mv	a0,s2
    8000177a:	fffff097          	auipc	ra,0xfffff
    8000177e:	2de080e7          	jalr	734(ra) # 80000a58 <inc_ref>
  for(i = 0; i < sz; i += PGSIZE){
    80001782:	6785                	lui	a5,0x1
    80001784:	94be                	add	s1,s1,a5
    80001786:	0534f363          	bgeu	s1,s3,800017cc <uvmcopy+0xc0>
    if((pte = walk(old, i, 0)) == 0)
    8000178a:	4601                	li	a2,0
    8000178c:	85a6                	mv	a1,s1
    8000178e:	8556                	mv	a0,s5
    80001790:	00000097          	auipc	ra,0x0
    80001794:	9ca080e7          	jalr	-1590(ra) # 8000115a <walk>
    80001798:	dd51                	beqz	a0,80001734 <uvmcopy+0x28>
    if((*pte & PTE_V) == 0)
    8000179a:	611c                	ld	a5,0(a0)
    8000179c:	0017f713          	andi	a4,a5,1
    800017a0:	d355                	beqz	a4,80001744 <uvmcopy+0x38>
    pa = PTE2PA(*pte);
    800017a2:	00a7d913          	srli	s2,a5,0xa
    800017a6:	0932                	slli	s2,s2,0xc
    flags = PTE_FLAGS(*pte);
    800017a8:	0007871b          	sext.w	a4,a5
    if(flags & PTE_W)
    800017ac:	0047f693          	andi	a3,a5,4
    800017b0:	f2d5                	bnez	a3,80001754 <uvmcopy+0x48>
    flags = PTE_FLAGS(*pte);
    800017b2:	3ff77713          	andi	a4,a4,1023
    800017b6:	b77d                	j	80001764 <uvmcopy+0x58>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017b8:	4685                	li	a3,1
    800017ba:	00c4d613          	srli	a2,s1,0xc
    800017be:	4581                	li	a1,0
    800017c0:	8552                	mv	a0,s4
    800017c2:	00000097          	auipc	ra,0x0
    800017c6:	c46080e7          	jalr	-954(ra) # 80001408 <uvmunmap>
  return -1;
    800017ca:	5bfd                	li	s7,-1
}
    800017cc:	855e                	mv	a0,s7
    800017ce:	60a6                	ld	ra,72(sp)
    800017d0:	6406                	ld	s0,64(sp)
    800017d2:	74e2                	ld	s1,56(sp)
    800017d4:	7942                	ld	s2,48(sp)
    800017d6:	79a2                	ld	s3,40(sp)
    800017d8:	7a02                	ld	s4,32(sp)
    800017da:	6ae2                	ld	s5,24(sp)
    800017dc:	6b42                	ld	s6,16(sp)
    800017de:	6ba2                	ld	s7,8(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret
  return 0;
    800017e4:	4b81                	li	s7,0
    800017e6:	b7dd                	j	800017cc <uvmcopy+0xc0>

00000000800017e8 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017e8:	1141                	addi	sp,sp,-16
    800017ea:	e406                	sd	ra,8(sp)
    800017ec:	e022                	sd	s0,0(sp)
    800017ee:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017f0:	4601                	li	a2,0
    800017f2:	00000097          	auipc	ra,0x0
    800017f6:	968080e7          	jalr	-1688(ra) # 8000115a <walk>
  if(pte == 0)
    800017fa:	c901                	beqz	a0,8000180a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017fc:	611c                	ld	a5,0(a0)
    800017fe:	9bbd                	andi	a5,a5,-17
    80001800:	e11c                	sd	a5,0(a0)
}
    80001802:	60a2                	ld	ra,8(sp)
    80001804:	6402                	ld	s0,0(sp)
    80001806:	0141                	addi	sp,sp,16
    80001808:	8082                	ret
    panic("uvmclear");
    8000180a:	00007517          	auipc	a0,0x7
    8000180e:	9de50513          	addi	a0,a0,-1570 # 800081e8 <digits+0x1a8>
    80001812:	fffff097          	auipc	ra,0xfffff
    80001816:	d2e080e7          	jalr	-722(ra) # 80000540 <panic>

000000008000181a <copyout>:
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;
  while(len > 0){
    8000181a:	c2d5                	beqz	a3,800018be <copyout+0xa4>
{
    8000181c:	711d                	addi	sp,sp,-96
    8000181e:	ec86                	sd	ra,88(sp)
    80001820:	e8a2                	sd	s0,80(sp)
    80001822:	e4a6                	sd	s1,72(sp)
    80001824:	e0ca                	sd	s2,64(sp)
    80001826:	fc4e                	sd	s3,56(sp)
    80001828:	f852                	sd	s4,48(sp)
    8000182a:	f456                	sd	s5,40(sp)
    8000182c:	f05a                	sd	s6,32(sp)
    8000182e:	ec5e                	sd	s7,24(sp)
    80001830:	e862                	sd	s8,16(sp)
    80001832:	e466                	sd	s9,8(sp)
    80001834:	1080                	addi	s0,sp,96
    80001836:	8baa                	mv	s7,a0
    80001838:	89ae                	mv	s3,a1
    8000183a:	8b32                	mv	s6,a2
    8000183c:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    8000183e:	7cfd                	lui	s9,0xfffff
    { 
      PageFaultHandler((void *)va0, pagetable);
      pa0= walkaddr(pagetable,va0);
    }
    #endif
    n = PGSIZE - (dstva - va0);
    80001840:	6c05                	lui	s8,0x1
    80001842:	a081                	j	80001882 <copyout+0x68>
      PageFaultHandler((void *)va0, pagetable);
    80001844:	85de                	mv	a1,s7
    80001846:	854a                	mv	a0,s2
    80001848:	00001097          	auipc	ra,0x1
    8000184c:	34e080e7          	jalr	846(ra) # 80002b96 <PageFaultHandler>
      pa0= walkaddr(pagetable,va0);
    80001850:	85ca                	mv	a1,s2
    80001852:	855e                	mv	a0,s7
    80001854:	00000097          	auipc	ra,0x0
    80001858:	9ac080e7          	jalr	-1620(ra) # 80001200 <walkaddr>
    8000185c:	8a2a                	mv	s4,a0
    8000185e:	a0b9                	j	800018ac <copyout+0x92>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001860:	41298533          	sub	a0,s3,s2
    80001864:	0004861b          	sext.w	a2,s1
    80001868:	85da                	mv	a1,s6
    8000186a:	9552                	add	a0,a0,s4
    8000186c:	fffff097          	auipc	ra,0xfffff
    80001870:	666080e7          	jalr	1638(ra) # 80000ed2 <memmove>

    len -= n;
    80001874:	409a8ab3          	sub	s5,s5,s1
    src += n;
    80001878:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    8000187a:	018909b3          	add	s3,s2,s8
  while(len > 0){
    8000187e:	020a8e63          	beqz	s5,800018ba <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    80001882:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    80001886:	85ca                	mv	a1,s2
    80001888:	855e                	mv	a0,s7
    8000188a:	00000097          	auipc	ra,0x0
    8000188e:	976080e7          	jalr	-1674(ra) # 80001200 <walkaddr>
    80001892:	8a2a                	mv	s4,a0
    if(pa0 == 0)
    80001894:	c51d                	beqz	a0,800018c2 <copyout+0xa8>
    pte=walk(pagetable,va0,0);
    80001896:	4601                	li	a2,0
    80001898:	85ca                	mv	a1,s2
    8000189a:	855e                	mv	a0,s7
    8000189c:	00000097          	auipc	ra,0x0
    800018a0:	8be080e7          	jalr	-1858(ra) # 8000115a <walk>
    if(flags & PTE_COW)
    800018a4:	611c                	ld	a5,0(a0)
    800018a6:	1007f793          	andi	a5,a5,256
    800018aa:	ffc9                	bnez	a5,80001844 <copyout+0x2a>
    n = PGSIZE - (dstva - va0);
    800018ac:	413904b3          	sub	s1,s2,s3
    800018b0:	94e2                	add	s1,s1,s8
    800018b2:	fa9af7e3          	bgeu	s5,s1,80001860 <copyout+0x46>
    800018b6:	84d6                	mv	s1,s5
    800018b8:	b765                	j	80001860 <copyout+0x46>
  }
  return 0;
    800018ba:	4501                	li	a0,0
    800018bc:	a021                	j	800018c4 <copyout+0xaa>
    800018be:	4501                	li	a0,0
}
    800018c0:	8082                	ret
      return -1;
    800018c2:	557d                	li	a0,-1
}
    800018c4:	60e6                	ld	ra,88(sp)
    800018c6:	6446                	ld	s0,80(sp)
    800018c8:	64a6                	ld	s1,72(sp)
    800018ca:	6906                	ld	s2,64(sp)
    800018cc:	79e2                	ld	s3,56(sp)
    800018ce:	7a42                	ld	s4,48(sp)
    800018d0:	7aa2                	ld	s5,40(sp)
    800018d2:	7b02                	ld	s6,32(sp)
    800018d4:	6be2                	ld	s7,24(sp)
    800018d6:	6c42                	ld	s8,16(sp)
    800018d8:	6ca2                	ld	s9,8(sp)
    800018da:	6125                	addi	sp,sp,96
    800018dc:	8082                	ret

00000000800018de <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018de:	caa5                	beqz	a3,8000194e <copyin+0x70>
{
    800018e0:	715d                	addi	sp,sp,-80
    800018e2:	e486                	sd	ra,72(sp)
    800018e4:	e0a2                	sd	s0,64(sp)
    800018e6:	fc26                	sd	s1,56(sp)
    800018e8:	f84a                	sd	s2,48(sp)
    800018ea:	f44e                	sd	s3,40(sp)
    800018ec:	f052                	sd	s4,32(sp)
    800018ee:	ec56                	sd	s5,24(sp)
    800018f0:	e85a                	sd	s6,16(sp)
    800018f2:	e45e                	sd	s7,8(sp)
    800018f4:	e062                	sd	s8,0(sp)
    800018f6:	0880                	addi	s0,sp,80
    800018f8:	8b2a                	mv	s6,a0
    800018fa:	8a2e                	mv	s4,a1
    800018fc:	8c32                	mv	s8,a2
    800018fe:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001900:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001902:	6a85                	lui	s5,0x1
    80001904:	a01d                	j	8000192a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001906:	018505b3          	add	a1,a0,s8
    8000190a:	0004861b          	sext.w	a2,s1
    8000190e:	412585b3          	sub	a1,a1,s2
    80001912:	8552                	mv	a0,s4
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	5be080e7          	jalr	1470(ra) # 80000ed2 <memmove>

    len -= n;
    8000191c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001920:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001922:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001926:	02098263          	beqz	s3,8000194a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000192a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000192e:	85ca                	mv	a1,s2
    80001930:	855a                	mv	a0,s6
    80001932:	00000097          	auipc	ra,0x0
    80001936:	8ce080e7          	jalr	-1842(ra) # 80001200 <walkaddr>
    if(pa0 == 0)
    8000193a:	cd01                	beqz	a0,80001952 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000193c:	418904b3          	sub	s1,s2,s8
    80001940:	94d6                	add	s1,s1,s5
    80001942:	fc99f2e3          	bgeu	s3,s1,80001906 <copyin+0x28>
    80001946:	84ce                	mv	s1,s3
    80001948:	bf7d                	j	80001906 <copyin+0x28>
  }
  return 0;
    8000194a:	4501                	li	a0,0
    8000194c:	a021                	j	80001954 <copyin+0x76>
    8000194e:	4501                	li	a0,0
}
    80001950:	8082                	ret
      return -1;
    80001952:	557d                	li	a0,-1
}
    80001954:	60a6                	ld	ra,72(sp)
    80001956:	6406                	ld	s0,64(sp)
    80001958:	74e2                	ld	s1,56(sp)
    8000195a:	7942                	ld	s2,48(sp)
    8000195c:	79a2                	ld	s3,40(sp)
    8000195e:	7a02                	ld	s4,32(sp)
    80001960:	6ae2                	ld	s5,24(sp)
    80001962:	6b42                	ld	s6,16(sp)
    80001964:	6ba2                	ld	s7,8(sp)
    80001966:	6c02                	ld	s8,0(sp)
    80001968:	6161                	addi	sp,sp,80
    8000196a:	8082                	ret

000000008000196c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000196c:	c2dd                	beqz	a3,80001a12 <copyinstr+0xa6>
{
    8000196e:	715d                	addi	sp,sp,-80
    80001970:	e486                	sd	ra,72(sp)
    80001972:	e0a2                	sd	s0,64(sp)
    80001974:	fc26                	sd	s1,56(sp)
    80001976:	f84a                	sd	s2,48(sp)
    80001978:	f44e                	sd	s3,40(sp)
    8000197a:	f052                	sd	s4,32(sp)
    8000197c:	ec56                	sd	s5,24(sp)
    8000197e:	e85a                	sd	s6,16(sp)
    80001980:	e45e                	sd	s7,8(sp)
    80001982:	0880                	addi	s0,sp,80
    80001984:	8a2a                	mv	s4,a0
    80001986:	8b2e                	mv	s6,a1
    80001988:	8bb2                	mv	s7,a2
    8000198a:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000198c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000198e:	6985                	lui	s3,0x1
    80001990:	a02d                	j	800019ba <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001992:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001996:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001998:	37fd                	addiw	a5,a5,-1
    8000199a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000199e:	60a6                	ld	ra,72(sp)
    800019a0:	6406                	ld	s0,64(sp)
    800019a2:	74e2                	ld	s1,56(sp)
    800019a4:	7942                	ld	s2,48(sp)
    800019a6:	79a2                	ld	s3,40(sp)
    800019a8:	7a02                	ld	s4,32(sp)
    800019aa:	6ae2                	ld	s5,24(sp)
    800019ac:	6b42                	ld	s6,16(sp)
    800019ae:	6ba2                	ld	s7,8(sp)
    800019b0:	6161                	addi	sp,sp,80
    800019b2:	8082                	ret
    srcva = va0 + PGSIZE;
    800019b4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019b8:	c8a9                	beqz	s1,80001a0a <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800019ba:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019be:	85ca                	mv	a1,s2
    800019c0:	8552                	mv	a0,s4
    800019c2:	00000097          	auipc	ra,0x0
    800019c6:	83e080e7          	jalr	-1986(ra) # 80001200 <walkaddr>
    if(pa0 == 0)
    800019ca:	c131                	beqz	a0,80001a0e <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800019cc:	417906b3          	sub	a3,s2,s7
    800019d0:	96ce                	add	a3,a3,s3
    800019d2:	00d4f363          	bgeu	s1,a3,800019d8 <copyinstr+0x6c>
    800019d6:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019d8:	955e                	add	a0,a0,s7
    800019da:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019de:	daf9                	beqz	a3,800019b4 <copyinstr+0x48>
    800019e0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019e2:	41650633          	sub	a2,a0,s6
    800019e6:	fff48593          	addi	a1,s1,-1
    800019ea:	95da                	add	a1,a1,s6
    while(n > 0){
    800019ec:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800019ee:	00f60733          	add	a4,a2,a5
    800019f2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbba28>
    800019f6:	df51                	beqz	a4,80001992 <copyinstr+0x26>
        *dst = *p;
    800019f8:	00e78023          	sb	a4,0(a5)
      --max;
    800019fc:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001a00:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a02:	fed796e3          	bne	a5,a3,800019ee <copyinstr+0x82>
      dst++;
    80001a06:	8b3e                	mv	s6,a5
    80001a08:	b775                	j	800019b4 <copyinstr+0x48>
    80001a0a:	4781                	li	a5,0
    80001a0c:	b771                	j	80001998 <copyinstr+0x2c>
      return -1;
    80001a0e:	557d                	li	a0,-1
    80001a10:	b779                	j	8000199e <copyinstr+0x32>
  int got_null = 0;
    80001a12:	4781                	li	a5,0
  if(got_null){
    80001a14:	37fd                	addiw	a5,a5,-1
    80001a16:	0007851b          	sext.w	a0,a5
}
    80001a1a:	8082                	ret

0000000080001a1c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a1c:	7139                	addi	sp,sp,-64
    80001a1e:	fc06                	sd	ra,56(sp)
    80001a20:	f822                	sd	s0,48(sp)
    80001a22:	f426                	sd	s1,40(sp)
    80001a24:	f04a                	sd	s2,32(sp)
    80001a26:	ec4e                	sd	s3,24(sp)
    80001a28:	e852                	sd	s4,16(sp)
    80001a2a:	e456                	sd	s5,8(sp)
    80001a2c:	e05a                	sd	s6,0(sp)
    80001a2e:	0080                	addi	s0,sp,64
    80001a30:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a32:	0022f497          	auipc	s1,0x22f
    80001a36:	5c648493          	addi	s1,s1,1478 # 80230ff8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a3a:	8b26                	mv	s6,s1
    80001a3c:	00006a97          	auipc	s5,0x6
    80001a40:	5c4a8a93          	addi	s5,s5,1476 # 80008000 <etext>
    80001a44:	04000937          	lui	s2,0x4000
    80001a48:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a4a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a4c:	00236a17          	auipc	s4,0x236
    80001a50:	7aca0a13          	addi	s4,s4,1964 # 802381f8 <tickslock>
    char *pa = kalloc();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	222080e7          	jalr	546(ra) # 80000c76 <kalloc>
    80001a5c:	862a                	mv	a2,a0
    if (pa == 0)
    80001a5e:	c131                	beqz	a0,80001aa2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a60:	416485b3          	sub	a1,s1,s6
    80001a64:	858d                	srai	a1,a1,0x3
    80001a66:	000ab783          	ld	a5,0(s5)
    80001a6a:	02f585b3          	mul	a1,a1,a5
    80001a6e:	2585                	addiw	a1,a1,1
    80001a70:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a74:	4719                	li	a4,6
    80001a76:	6685                	lui	a3,0x1
    80001a78:	40b905b3          	sub	a1,s2,a1
    80001a7c:	854e                	mv	a0,s3
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	864080e7          	jalr	-1948(ra) # 800012e2 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a86:	1c848493          	addi	s1,s1,456
    80001a8a:	fd4495e3          	bne	s1,s4,80001a54 <proc_mapstacks+0x38>
  }
}
    80001a8e:	70e2                	ld	ra,56(sp)
    80001a90:	7442                	ld	s0,48(sp)
    80001a92:	74a2                	ld	s1,40(sp)
    80001a94:	7902                	ld	s2,32(sp)
    80001a96:	69e2                	ld	s3,24(sp)
    80001a98:	6a42                	ld	s4,16(sp)
    80001a9a:	6aa2                	ld	s5,8(sp)
    80001a9c:	6b02                	ld	s6,0(sp)
    80001a9e:	6121                	addi	sp,sp,64
    80001aa0:	8082                	ret
      panic("kalloc");
    80001aa2:	00006517          	auipc	a0,0x6
    80001aa6:	75650513          	addi	a0,a0,1878 # 800081f8 <digits+0x1b8>
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	a96080e7          	jalr	-1386(ra) # 80000540 <panic>

0000000080001ab2 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001ab2:	7139                	addi	sp,sp,-64
    80001ab4:	fc06                	sd	ra,56(sp)
    80001ab6:	f822                	sd	s0,48(sp)
    80001ab8:	f426                	sd	s1,40(sp)
    80001aba:	f04a                	sd	s2,32(sp)
    80001abc:	ec4e                	sd	s3,24(sp)
    80001abe:	e852                	sd	s4,16(sp)
    80001ac0:	e456                	sd	s5,8(sp)
    80001ac2:	e05a                	sd	s6,0(sp)
    80001ac4:	0080                	addi	s0,sp,64
  struct proc *p;
  initlock(&pid_lock, "nextpid");
    80001ac6:	00006597          	auipc	a1,0x6
    80001aca:	73a58593          	addi	a1,a1,1850 # 80008200 <digits+0x1c0>
    80001ace:	0022f517          	auipc	a0,0x22f
    80001ad2:	0fa50513          	addi	a0,a0,250 # 80230bc8 <pid_lock>
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	214080e7          	jalr	532(ra) # 80000cea <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ade:	00006597          	auipc	a1,0x6
    80001ae2:	72a58593          	addi	a1,a1,1834 # 80008208 <digits+0x1c8>
    80001ae6:	0022f517          	auipc	a0,0x22f
    80001aea:	0fa50513          	addi	a0,a0,250 # 80230be0 <wait_lock>
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	1fc080e7          	jalr	508(ra) # 80000cea <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001af6:	0022f497          	auipc	s1,0x22f
    80001afa:	50248493          	addi	s1,s1,1282 # 80230ff8 <proc>
  {
    initlock(&p->lock, "proc");
    80001afe:	00006b17          	auipc	s6,0x6
    80001b02:	71ab0b13          	addi	s6,s6,1818 # 80008218 <digits+0x1d8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001b06:	8aa6                	mv	s5,s1
    80001b08:	00006a17          	auipc	s4,0x6
    80001b0c:	4f8a0a13          	addi	s4,s4,1272 # 80008000 <etext>
    80001b10:	04000937          	lui	s2,0x4000
    80001b14:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b16:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b18:	00236997          	auipc	s3,0x236
    80001b1c:	6e098993          	addi	s3,s3,1760 # 802381f8 <tickslock>
    initlock(&p->lock, "proc");
    80001b20:	85da                	mv	a1,s6
    80001b22:	8526                	mv	a0,s1
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	1c6080e7          	jalr	454(ra) # 80000cea <initlock>
    p->state = UNUSED;
    80001b2c:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b30:	415487b3          	sub	a5,s1,s5
    80001b34:	878d                	srai	a5,a5,0x3
    80001b36:	000a3703          	ld	a4,0(s4)
    80001b3a:	02e787b3          	mul	a5,a5,a4
    80001b3e:	2785                	addiw	a5,a5,1
    80001b40:	00d7979b          	slliw	a5,a5,0xd
    80001b44:	40f907b3          	sub	a5,s2,a5
    80001b48:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b4a:	1c848493          	addi	s1,s1,456
    80001b4e:	fd3499e3          	bne	s1,s3,80001b20 <procinit+0x6e>
  }
}
    80001b52:	70e2                	ld	ra,56(sp)
    80001b54:	7442                	ld	s0,48(sp)
    80001b56:	74a2                	ld	s1,40(sp)
    80001b58:	7902                	ld	s2,32(sp)
    80001b5a:	69e2                	ld	s3,24(sp)
    80001b5c:	6a42                	ld	s4,16(sp)
    80001b5e:	6aa2                	ld	s5,8(sp)
    80001b60:	6b02                	ld	s6,0(sp)
    80001b62:	6121                	addi	sp,sp,64
    80001b64:	8082                	ret

0000000080001b66 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b66:	1141                	addi	sp,sp,-16
    80001b68:	e422                	sd	s0,8(sp)
    80001b6a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b6c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b6e:	2501                	sext.w	a0,a0
    80001b70:	6422                	ld	s0,8(sp)
    80001b72:	0141                	addi	sp,sp,16
    80001b74:	8082                	ret

0000000080001b76 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b76:	1141                	addi	sp,sp,-16
    80001b78:	e422                	sd	s0,8(sp)
    80001b7a:	0800                	addi	s0,sp,16
    80001b7c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b7e:	2781                	sext.w	a5,a5
    80001b80:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b82:	0022f517          	auipc	a0,0x22f
    80001b86:	07650513          	addi	a0,a0,118 # 80230bf8 <cpus>
    80001b8a:	953e                	add	a0,a0,a5
    80001b8c:	6422                	ld	s0,8(sp)
    80001b8e:	0141                	addi	sp,sp,16
    80001b90:	8082                	ret

0000000080001b92 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b92:	1101                	addi	sp,sp,-32
    80001b94:	ec06                	sd	ra,24(sp)
    80001b96:	e822                	sd	s0,16(sp)
    80001b98:	e426                	sd	s1,8(sp)
    80001b9a:	1000                	addi	s0,sp,32
  push_off();
    80001b9c:	fffff097          	auipc	ra,0xfffff
    80001ba0:	192080e7          	jalr	402(ra) # 80000d2e <push_off>
    80001ba4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ba6:	2781                	sext.w	a5,a5
    80001ba8:	079e                	slli	a5,a5,0x7
    80001baa:	0022f717          	auipc	a4,0x22f
    80001bae:	01e70713          	addi	a4,a4,30 # 80230bc8 <pid_lock>
    80001bb2:	97ba                	add	a5,a5,a4
    80001bb4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	218080e7          	jalr	536(ra) # 80000dce <pop_off>
  return p;
}
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	60e2                	ld	ra,24(sp)
    80001bc2:	6442                	ld	s0,16(sp)
    80001bc4:	64a2                	ld	s1,8(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret

0000000080001bca <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bca:	1141                	addi	sp,sp,-16
    80001bcc:	e406                	sd	ra,8(sp)
    80001bce:	e022                	sd	s0,0(sp)
    80001bd0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bd2:	00000097          	auipc	ra,0x0
    80001bd6:	fc0080e7          	jalr	-64(ra) # 80001b92 <myproc>
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	254080e7          	jalr	596(ra) # 80000e2e <release>

  if (first)
    80001be2:	00007797          	auipc	a5,0x7
    80001be6:	cbe7a783          	lw	a5,-834(a5) # 800088a0 <first.1>
    80001bea:	eb89                	bnez	a5,80001bfc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bec:	00001097          	auipc	ra,0x1
    80001bf0:	05c080e7          	jalr	92(ra) # 80002c48 <usertrapret>
}
    80001bf4:	60a2                	ld	ra,8(sp)
    80001bf6:	6402                	ld	s0,0(sp)
    80001bf8:	0141                	addi	sp,sp,16
    80001bfa:	8082                	ret
    first = 0;
    80001bfc:	00007797          	auipc	a5,0x7
    80001c00:	ca07a223          	sw	zero,-860(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001c04:	4505                	li	a0,1
    80001c06:	00002097          	auipc	ra,0x2
    80001c0a:	136080e7          	jalr	310(ra) # 80003d3c <fsinit>
    80001c0e:	bff9                	j	80001bec <forkret+0x22>

0000000080001c10 <allocpid>:
{
    80001c10:	1101                	addi	sp,sp,-32
    80001c12:	ec06                	sd	ra,24(sp)
    80001c14:	e822                	sd	s0,16(sp)
    80001c16:	e426                	sd	s1,8(sp)
    80001c18:	e04a                	sd	s2,0(sp)
    80001c1a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c1c:	0022f917          	auipc	s2,0x22f
    80001c20:	fac90913          	addi	s2,s2,-84 # 80230bc8 <pid_lock>
    80001c24:	854a                	mv	a0,s2
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	154080e7          	jalr	340(ra) # 80000d7a <acquire>
  pid = nextpid;
    80001c2e:	00007797          	auipc	a5,0x7
    80001c32:	c7678793          	addi	a5,a5,-906 # 800088a4 <nextpid>
    80001c36:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c38:	0014871b          	addiw	a4,s1,1
    80001c3c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c3e:	854a                	mv	a0,s2
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	1ee080e7          	jalr	494(ra) # 80000e2e <release>
}
    80001c48:	8526                	mv	a0,s1
    80001c4a:	60e2                	ld	ra,24(sp)
    80001c4c:	6442                	ld	s0,16(sp)
    80001c4e:	64a2                	ld	s1,8(sp)
    80001c50:	6902                	ld	s2,0(sp)
    80001c52:	6105                	addi	sp,sp,32
    80001c54:	8082                	ret

0000000080001c56 <proc_pagetable>:
{
    80001c56:	1101                	addi	sp,sp,-32
    80001c58:	ec06                	sd	ra,24(sp)
    80001c5a:	e822                	sd	s0,16(sp)
    80001c5c:	e426                	sd	s1,8(sp)
    80001c5e:	e04a                	sd	s2,0(sp)
    80001c60:	1000                	addi	s0,sp,32
    80001c62:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	868080e7          	jalr	-1944(ra) # 800014cc <uvmcreate>
    80001c6c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c6e:	c121                	beqz	a0,80001cae <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c70:	4729                	li	a4,10
    80001c72:	00005697          	auipc	a3,0x5
    80001c76:	38e68693          	addi	a3,a3,910 # 80007000 <_trampoline>
    80001c7a:	6605                	lui	a2,0x1
    80001c7c:	040005b7          	lui	a1,0x4000
    80001c80:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c82:	05b2                	slli	a1,a1,0xc
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	5be080e7          	jalr	1470(ra) # 80001242 <mappages>
    80001c8c:	02054863          	bltz	a0,80001cbc <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c90:	4719                	li	a4,6
    80001c92:	05893683          	ld	a3,88(s2)
    80001c96:	6605                	lui	a2,0x1
    80001c98:	020005b7          	lui	a1,0x2000
    80001c9c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c9e:	05b6                	slli	a1,a1,0xd
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	5a0080e7          	jalr	1440(ra) # 80001242 <mappages>
    80001caa:	02054163          	bltz	a0,80001ccc <proc_pagetable+0x76>
}
    80001cae:	8526                	mv	a0,s1
    80001cb0:	60e2                	ld	ra,24(sp)
    80001cb2:	6442                	ld	s0,16(sp)
    80001cb4:	64a2                	ld	s1,8(sp)
    80001cb6:	6902                	ld	s2,0(sp)
    80001cb8:	6105                	addi	sp,sp,32
    80001cba:	8082                	ret
    uvmfree(pagetable, 0);
    80001cbc:	4581                	li	a1,0
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	a12080e7          	jalr	-1518(ra) # 800016d2 <uvmfree>
    return 0;
    80001cc8:	4481                	li	s1,0
    80001cca:	b7d5                	j	80001cae <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ccc:	4681                	li	a3,0
    80001cce:	4605                	li	a2,1
    80001cd0:	040005b7          	lui	a1,0x4000
    80001cd4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cd6:	05b2                	slli	a1,a1,0xc
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	72e080e7          	jalr	1838(ra) # 80001408 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ce2:	4581                	li	a1,0
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	9ec080e7          	jalr	-1556(ra) # 800016d2 <uvmfree>
    return 0;
    80001cee:	4481                	li	s1,0
    80001cf0:	bf7d                	j	80001cae <proc_pagetable+0x58>

0000000080001cf2 <proc_freepagetable>:
{
    80001cf2:	1101                	addi	sp,sp,-32
    80001cf4:	ec06                	sd	ra,24(sp)
    80001cf6:	e822                	sd	s0,16(sp)
    80001cf8:	e426                	sd	s1,8(sp)
    80001cfa:	e04a                	sd	s2,0(sp)
    80001cfc:	1000                	addi	s0,sp,32
    80001cfe:	84aa                	mv	s1,a0
    80001d00:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d02:	4681                	li	a3,0
    80001d04:	4605                	li	a2,1
    80001d06:	040005b7          	lui	a1,0x4000
    80001d0a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d0c:	05b2                	slli	a1,a1,0xc
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	6fa080e7          	jalr	1786(ra) # 80001408 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d16:	4681                	li	a3,0
    80001d18:	4605                	li	a2,1
    80001d1a:	020005b7          	lui	a1,0x2000
    80001d1e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d20:	05b6                	slli	a1,a1,0xd
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	6e4080e7          	jalr	1764(ra) # 80001408 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d2c:	85ca                	mv	a1,s2
    80001d2e:	8526                	mv	a0,s1
    80001d30:	00000097          	auipc	ra,0x0
    80001d34:	9a2080e7          	jalr	-1630(ra) # 800016d2 <uvmfree>
}
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6902                	ld	s2,0(sp)
    80001d40:	6105                	addi	sp,sp,32
    80001d42:	8082                	ret

0000000080001d44 <freeproc>:
{
    80001d44:	1101                	addi	sp,sp,-32
    80001d46:	ec06                	sd	ra,24(sp)
    80001d48:	e822                	sd	s0,16(sp)
    80001d4a:	e426                	sd	s1,8(sp)
    80001d4c:	1000                	addi	s0,sp,32
    80001d4e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d50:	6d28                	ld	a0,88(a0)
    80001d52:	c509                	beqz	a0,80001d5c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	de0080e7          	jalr	-544(ra) # 80000b34 <kfree>
  if (p->alarm_tp)
    80001d5c:	1984b503          	ld	a0,408(s1)
    80001d60:	c509                	beqz	a0,80001d6a <freeproc+0x26>
    kfree((void *)p->alarm_tp);
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	dd2080e7          	jalr	-558(ra) # 80000b34 <kfree>
  p->trapframe = 0;
    80001d6a:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d6e:	68a8                	ld	a0,80(s1)
    80001d70:	c511                	beqz	a0,80001d7c <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    80001d72:	64ac                	ld	a1,72(s1)
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	f7e080e7          	jalr	-130(ra) # 80001cf2 <proc_freepagetable>
  p->pagetable = 0;
    80001d7c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d80:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d84:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d88:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d8c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d90:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d94:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d98:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d9c:	0004ac23          	sw	zero,24(s1)
}
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6105                	addi	sp,sp,32
    80001da8:	8082                	ret

0000000080001daa <allocproc>:
{
    80001daa:	1101                	addi	sp,sp,-32
    80001dac:	ec06                	sd	ra,24(sp)
    80001dae:	e822                	sd	s0,16(sp)
    80001db0:	e426                	sd	s1,8(sp)
    80001db2:	e04a                	sd	s2,0(sp)
    80001db4:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001db6:	0022f497          	auipc	s1,0x22f
    80001dba:	24248493          	addi	s1,s1,578 # 80230ff8 <proc>
    80001dbe:	00236917          	auipc	s2,0x236
    80001dc2:	43a90913          	addi	s2,s2,1082 # 802381f8 <tickslock>
    acquire(&p->lock);
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	fb2080e7          	jalr	-78(ra) # 80000d7a <acquire>
    if (p->state == UNUSED)
    80001dd0:	4c9c                	lw	a5,24(s1)
    80001dd2:	cf81                	beqz	a5,80001dea <allocproc+0x40>
      release(&p->lock);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	058080e7          	jalr	88(ra) # 80000e2e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dde:	1c848493          	addi	s1,s1,456
    80001de2:	ff2492e3          	bne	s1,s2,80001dc6 <allocproc+0x1c>
  return 0;
    80001de6:	4481                	li	s1,0
    80001de8:	a85d                	j	80001e9e <allocproc+0xf4>
  p->pid = allocpid();
    80001dea:	00000097          	auipc	ra,0x0
    80001dee:	e26080e7          	jalr	-474(ra) # 80001c10 <allocpid>
    80001df2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001df4:	4785                	li	a5,1
    80001df6:	cc9c                	sw	a5,24(s1)
  p->atime = 0;
    80001df8:	1804a023          	sw	zero,384(s1)
  p->readcount = 0;
    80001dfc:	0204aa23          	sw	zero,52(s1)
  p->n = 0;
    80001e00:	1804b423          	sd	zero,392(s1)
  p->alarmhandler = 0;
    80001e04:	1604bc23          	sd	zero,376(s1)
  p->astate = 0;
    80001e08:	1a04a023          	sw	zero,416(s1)
  p->aset = 0;
    80001e0c:	1804a823          	sw	zero,400(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e66080e7          	jalr	-410(ra) # 80000c76 <kalloc>
    80001e18:	892a                	mv	s2,a0
    80001e1a:	eca8                	sd	a0,88(s1)
    80001e1c:	c941                	beqz	a0,80001eac <allocproc+0x102>
  if ((p->alarm_tp = (struct trapframe *)kalloc()) == 0)
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	e58080e7          	jalr	-424(ra) # 80000c76 <kalloc>
    80001e26:	18a4bc23          	sd	a0,408(s1)
    80001e2a:	c94d                	beqz	a0,80001edc <allocproc+0x132>
  p->pagetable = proc_pagetable(p);
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	e28080e7          	jalr	-472(ra) # 80001c56 <proc_pagetable>
    80001e36:	892a                	mv	s2,a0
    80001e38:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001e3a:	c549                	beqz	a0,80001ec4 <allocproc+0x11a>
  memset(&p->context, 0, sizeof(p->context));
    80001e3c:	07000613          	li	a2,112
    80001e40:	4581                	li	a1,0
    80001e42:	06048513          	addi	a0,s1,96
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	030080e7          	jalr	48(ra) # 80000e76 <memset>
  p->context.ra = (uint64)forkret;
    80001e4e:	00000797          	auipc	a5,0x0
    80001e52:	d7c78793          	addi	a5,a5,-644 # 80001bca <forkret>
    80001e56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e58:	60bc                	ld	a5,64(s1)
    80001e5a:	6705                	lui	a4,0x1
    80001e5c:	97ba                	add	a5,a5,a4
    80001e5e:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001e60:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001e64:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001e68:	00007797          	auipc	a5,0x7
    80001e6c:	ad87a783          	lw	a5,-1320(a5) # 80008940 <ticks>
    80001e70:	16f4a623          	sw	a5,364(s1)
  p->wtime = 0;
    80001e74:	1a04a623          	sw	zero,428(s1)
  p->hastosleep=0;
    80001e78:	1a04a823          	sw	zero,432(s1)
   p->priority=50;
    80001e7c:	03200793          	li	a5,50
    80001e80:	1af4a223          	sw	a5,420(s1)
  p->rbi=25;
    80001e84:	47e5                	li	a5,25
    80001e86:	1af4aa23          	sw	a5,436(s1)
  p->runtime=0;
    80001e8a:	1a04ae23          	sw	zero,444(s1)
  p->times_scheduled=0;
    80001e8e:	1c04a023          	sw	zero,448(s1)
  p->stime=0;
    80001e92:	1c04a223          	sw	zero,452(s1)
    p->dp=p->rbi+p->priority;
    80001e96:	04b00793          	li	a5,75
    80001e9a:	1af4ac23          	sw	a5,440(s1)
}
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	60e2                	ld	ra,24(sp)
    80001ea2:	6442                	ld	s0,16(sp)
    80001ea4:	64a2                	ld	s1,8(sp)
    80001ea6:	6902                	ld	s2,0(sp)
    80001ea8:	6105                	addi	sp,sp,32
    80001eaa:	8082                	ret
    freeproc(p);
    80001eac:	8526                	mv	a0,s1
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	e96080e7          	jalr	-362(ra) # 80001d44 <freeproc>
    release(&p->lock);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	f76080e7          	jalr	-138(ra) # 80000e2e <release>
    return 0;
    80001ec0:	84ca                	mv	s1,s2
    80001ec2:	bff1                	j	80001e9e <allocproc+0xf4>
    freeproc(p);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	00000097          	auipc	ra,0x0
    80001eca:	e7e080e7          	jalr	-386(ra) # 80001d44 <freeproc>
    release(&p->lock);
    80001ece:	8526                	mv	a0,s1
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	f5e080e7          	jalr	-162(ra) # 80000e2e <release>
    return 0;
    80001ed8:	84ca                	mv	s1,s2
    80001eda:	b7d1                	j	80001e9e <allocproc+0xf4>
    return 0;
    80001edc:	84aa                	mv	s1,a0
    80001ede:	b7c1                	j	80001e9e <allocproc+0xf4>

0000000080001ee0 <userinit>:
{
    80001ee0:	1101                	addi	sp,sp,-32
    80001ee2:	ec06                	sd	ra,24(sp)
    80001ee4:	e822                	sd	s0,16(sp)
    80001ee6:	e426                	sd	s1,8(sp)
    80001ee8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	ec0080e7          	jalr	-320(ra) # 80001daa <allocproc>
    80001ef2:	84aa                	mv	s1,a0
  initproc = p;
    80001ef4:	00007797          	auipc	a5,0x7
    80001ef8:	a4a7b223          	sd	a0,-1468(a5) # 80008938 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001efc:	03400613          	li	a2,52
    80001f00:	00007597          	auipc	a1,0x7
    80001f04:	9b058593          	addi	a1,a1,-1616 # 800088b0 <initcode>
    80001f08:	6928                	ld	a0,80(a0)
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	5f0080e7          	jalr	1520(ra) # 800014fa <uvmfirst>
  p->sz = PGSIZE;
    80001f12:	6785                	lui	a5,0x1
    80001f14:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f16:	6cb8                	ld	a4,88(s1)
    80001f18:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f1c:	6cb8                	ld	a4,88(s1)
    80001f1e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f20:	4641                	li	a2,16
    80001f22:	00006597          	auipc	a1,0x6
    80001f26:	2fe58593          	addi	a1,a1,766 # 80008220 <digits+0x1e0>
    80001f2a:	15848513          	addi	a0,s1,344
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	092080e7          	jalr	146(ra) # 80000fc0 <safestrcpy>
  p->cwd = namei("/");
    80001f36:	00006517          	auipc	a0,0x6
    80001f3a:	2fa50513          	addi	a0,a0,762 # 80008230 <digits+0x1f0>
    80001f3e:	00003097          	auipc	ra,0x3
    80001f42:	828080e7          	jalr	-2008(ra) # 80004766 <namei>
    80001f46:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f4a:	478d                	li	a5,3
    80001f4c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	ede080e7          	jalr	-290(ra) # 80000e2e <release>
}
    80001f58:	60e2                	ld	ra,24(sp)
    80001f5a:	6442                	ld	s0,16(sp)
    80001f5c:	64a2                	ld	s1,8(sp)
    80001f5e:	6105                	addi	sp,sp,32
    80001f60:	8082                	ret

0000000080001f62 <growproc>:
{
    80001f62:	1101                	addi	sp,sp,-32
    80001f64:	ec06                	sd	ra,24(sp)
    80001f66:	e822                	sd	s0,16(sp)
    80001f68:	e426                	sd	s1,8(sp)
    80001f6a:	e04a                	sd	s2,0(sp)
    80001f6c:	1000                	addi	s0,sp,32
    80001f6e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	c22080e7          	jalr	-990(ra) # 80001b92 <myproc>
    80001f78:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f7a:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f7c:	01204c63          	bgtz	s2,80001f94 <growproc+0x32>
  else if (n < 0)
    80001f80:	02094663          	bltz	s2,80001fac <growproc+0x4a>
  p->sz = sz;
    80001f84:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f86:	4501                	li	a0,0
}
    80001f88:	60e2                	ld	ra,24(sp)
    80001f8a:	6442                	ld	s0,16(sp)
    80001f8c:	64a2                	ld	s1,8(sp)
    80001f8e:	6902                	ld	s2,0(sp)
    80001f90:	6105                	addi	sp,sp,32
    80001f92:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f94:	4691                	li	a3,4
    80001f96:	00b90633          	add	a2,s2,a1
    80001f9a:	6928                	ld	a0,80(a0)
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	618080e7          	jalr	1560(ra) # 800015b4 <uvmalloc>
    80001fa4:	85aa                	mv	a1,a0
    80001fa6:	fd79                	bnez	a0,80001f84 <growproc+0x22>
      return -1;
    80001fa8:	557d                	li	a0,-1
    80001faa:	bff9                	j	80001f88 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fac:	00b90633          	add	a2,s2,a1
    80001fb0:	6928                	ld	a0,80(a0)
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	5ba080e7          	jalr	1466(ra) # 8000156c <uvmdealloc>
    80001fba:	85aa                	mv	a1,a0
    80001fbc:	b7e1                	j	80001f84 <growproc+0x22>

0000000080001fbe <fork>:
{
    80001fbe:	7139                	addi	sp,sp,-64
    80001fc0:	fc06                	sd	ra,56(sp)
    80001fc2:	f822                	sd	s0,48(sp)
    80001fc4:	f426                	sd	s1,40(sp)
    80001fc6:	f04a                	sd	s2,32(sp)
    80001fc8:	ec4e                	sd	s3,24(sp)
    80001fca:	e852                	sd	s4,16(sp)
    80001fcc:	e456                	sd	s5,8(sp)
    80001fce:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001fd0:	00000097          	auipc	ra,0x0
    80001fd4:	bc2080e7          	jalr	-1086(ra) # 80001b92 <myproc>
    80001fd8:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	dd0080e7          	jalr	-560(ra) # 80001daa <allocproc>
    80001fe2:	10050c63          	beqz	a0,800020fa <fork+0x13c>
    80001fe6:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fe8:	048ab603          	ld	a2,72(s5)
    80001fec:	692c                	ld	a1,80(a0)
    80001fee:	050ab503          	ld	a0,80(s5)
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	71a080e7          	jalr	1818(ra) # 8000170c <uvmcopy>
    80001ffa:	04054863          	bltz	a0,8000204a <fork+0x8c>
  np->sz = p->sz;
    80001ffe:	048ab783          	ld	a5,72(s5)
    80002002:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002006:	058ab683          	ld	a3,88(s5)
    8000200a:	87b6                	mv	a5,a3
    8000200c:	058a3703          	ld	a4,88(s4)
    80002010:	12068693          	addi	a3,a3,288
    80002014:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002018:	6788                	ld	a0,8(a5)
    8000201a:	6b8c                	ld	a1,16(a5)
    8000201c:	6f90                	ld	a2,24(a5)
    8000201e:	01073023          	sd	a6,0(a4)
    80002022:	e708                	sd	a0,8(a4)
    80002024:	eb0c                	sd	a1,16(a4)
    80002026:	ef10                	sd	a2,24(a4)
    80002028:	02078793          	addi	a5,a5,32
    8000202c:	02070713          	addi	a4,a4,32
    80002030:	fed792e3          	bne	a5,a3,80002014 <fork+0x56>
  np->trapframe->a0 = 0;
    80002034:	058a3783          	ld	a5,88(s4)
    80002038:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    8000203c:	0d0a8493          	addi	s1,s5,208
    80002040:	0d0a0913          	addi	s2,s4,208
    80002044:	150a8993          	addi	s3,s5,336
    80002048:	a00d                	j	8000206a <fork+0xac>
    freeproc(np);
    8000204a:	8552                	mv	a0,s4
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	cf8080e7          	jalr	-776(ra) # 80001d44 <freeproc>
    release(&np->lock);
    80002054:	8552                	mv	a0,s4
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	dd8080e7          	jalr	-552(ra) # 80000e2e <release>
    return -1;
    8000205e:	597d                	li	s2,-1
    80002060:	a059                	j	800020e6 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80002062:	04a1                	addi	s1,s1,8
    80002064:	0921                	addi	s2,s2,8
    80002066:	01348b63          	beq	s1,s3,8000207c <fork+0xbe>
    if (p->ofile[i])
    8000206a:	6088                	ld	a0,0(s1)
    8000206c:	d97d                	beqz	a0,80002062 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    8000206e:	00003097          	auipc	ra,0x3
    80002072:	d8e080e7          	jalr	-626(ra) # 80004dfc <filedup>
    80002076:	00a93023          	sd	a0,0(s2)
    8000207a:	b7e5                	j	80002062 <fork+0xa4>
  np->cwd = idup(p->cwd);
    8000207c:	150ab503          	ld	a0,336(s5)
    80002080:	00002097          	auipc	ra,0x2
    80002084:	efc080e7          	jalr	-260(ra) # 80003f7c <idup>
    80002088:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000208c:	4641                	li	a2,16
    8000208e:	158a8593          	addi	a1,s5,344
    80002092:	158a0513          	addi	a0,s4,344
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	f2a080e7          	jalr	-214(ra) # 80000fc0 <safestrcpy>
  pid = np->pid;
    8000209e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    800020a2:	8552                	mv	a0,s4
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	d8a080e7          	jalr	-630(ra) # 80000e2e <release>
  acquire(&wait_lock);
    800020ac:	0022f497          	auipc	s1,0x22f
    800020b0:	b3448493          	addi	s1,s1,-1228 # 80230be0 <wait_lock>
    800020b4:	8526                	mv	a0,s1
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	cc4080e7          	jalr	-828(ra) # 80000d7a <acquire>
  np->parent = p;
    800020be:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    800020c2:	8526                	mv	a0,s1
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	d6a080e7          	jalr	-662(ra) # 80000e2e <release>
  acquire(&np->lock);
    800020cc:	8552                	mv	a0,s4
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	cac080e7          	jalr	-852(ra) # 80000d7a <acquire>
  np->state = RUNNABLE;
    800020d6:	478d                	li	a5,3
    800020d8:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800020dc:	8552                	mv	a0,s4
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	d50080e7          	jalr	-688(ra) # 80000e2e <release>
}
    800020e6:	854a                	mv	a0,s2
    800020e8:	70e2                	ld	ra,56(sp)
    800020ea:	7442                	ld	s0,48(sp)
    800020ec:	74a2                	ld	s1,40(sp)
    800020ee:	7902                	ld	s2,32(sp)
    800020f0:	69e2                	ld	s3,24(sp)
    800020f2:	6a42                	ld	s4,16(sp)
    800020f4:	6aa2                	ld	s5,8(sp)
    800020f6:	6121                	addi	sp,sp,64
    800020f8:	8082                	ret
    return -1;
    800020fa:	597d                	li	s2,-1
    800020fc:	b7ed                	j	800020e6 <fork+0x128>

00000000800020fe <scheduler>:
{
    800020fe:	711d                	addi	sp,sp,-96
    80002100:	ec86                	sd	ra,88(sp)
    80002102:	e8a2                	sd	s0,80(sp)
    80002104:	e4a6                	sd	s1,72(sp)
    80002106:	e0ca                	sd	s2,64(sp)
    80002108:	fc4e                	sd	s3,56(sp)
    8000210a:	f852                	sd	s4,48(sp)
    8000210c:	f456                	sd	s5,40(sp)
    8000210e:	f05a                	sd	s6,32(sp)
    80002110:	ec5e                	sd	s7,24(sp)
    80002112:	e862                	sd	s8,16(sp)
    80002114:	e466                	sd	s9,8(sp)
    80002116:	e06a                	sd	s10,0(sp)
    80002118:	1080                	addi	s0,sp,96
    8000211a:	8792                	mv	a5,tp
  int id = r_tp();
    8000211c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000211e:	00779693          	slli	a3,a5,0x7
    80002122:	0022f717          	auipc	a4,0x22f
    80002126:	aa670713          	addi	a4,a4,-1370 # 80230bc8 <pid_lock>
    8000212a:	9736                	add	a4,a4,a3
    8000212c:	02073823          	sd	zero,48(a4)
        swtch(&c->context,&t->context);
    80002130:	0022f717          	auipc	a4,0x22f
    80002134:	ad070713          	addi	a4,a4,-1328 # 80230c00 <cpus+0x8>
    80002138:	00e68d33          	add	s10,a3,a4
    t = 0;
    8000213c:	4c01                	li	s8,0
      if(p->state==RUNNABLE)
    8000213e:	4a8d                	li	s5,3
    for(p=proc;p<&proc[NPROC];p++)
    80002140:	00236b17          	auipc	s6,0x236
    80002144:	0b8b0b13          	addi	s6,s6,184 # 802381f8 <tickslock>
        c->proc=t;
    80002148:	0022fc97          	auipc	s9,0x22f
    8000214c:	a80c8c93          	addi	s9,s9,-1408 # 80230bc8 <pid_lock>
    80002150:	9cb6                	add	s9,s9,a3
    80002152:	a0e1                	j	8000221a <scheduler+0x11c>
        if(t==0)
    80002154:	080b8163          	beqz	s7,800021d6 <scheduler+0xd8>
        else if(t->dp>p->dp)
    80002158:	1b8ba703          	lw	a4,440(s7) # fffffffffffff1b8 <end+0xffffffff7fdbbbe0>
    8000215c:	ff092783          	lw	a5,-16(s2)
    80002160:	06e7cd63          	blt	a5,a4,800021da <scheduler+0xdc>
        else if(t->dp==p->dp)
    80002164:	06f71c63          	bne	a4,a5,800021dc <scheduler+0xde>
          if(t->times_scheduled>p->times_scheduled)
    80002168:	1c0ba703          	lw	a4,448(s7)
    8000216c:	ff892783          	lw	a5,-8(s2)
    80002170:	0ce7c563          	blt	a5,a4,8000223a <scheduler+0x13c>
          else if(t->times_scheduled==p->times_scheduled && t->ctime>p->ctime)
    80002174:	06f71463          	bne	a4,a5,800021dc <scheduler+0xde>
    80002178:	16cba703          	lw	a4,364(s7)
    8000217c:	fa492783          	lw	a5,-92(s2)
    80002180:	04e7fe63          	bgeu	a5,a4,800021dc <scheduler+0xde>
    80002184:	8ba6                	mv	s7,s1
    80002186:	a899                	j	800021dc <scheduler+0xde>
      acquire(&t->lock);
    80002188:	84de                	mv	s1,s7
    8000218a:	855e                	mv	a0,s7
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	bee080e7          	jalr	-1042(ra) # 80000d7a <acquire>
      if(t->state==RUNNABLE)
    80002194:	018ba783          	lw	a5,24(s7)
    80002198:	03579963          	bne	a5,s5,800021ca <scheduler+0xcc>
        t->state=RUNNING;
    8000219c:	4791                	li	a5,4
    8000219e:	00fbac23          	sw	a5,24(s7)
        t->runtime=0;
    800021a2:	1a0bae23          	sw	zero,444(s7)
        t->stime=0;
    800021a6:	1c0ba223          	sw	zero,452(s7)
        t->times_scheduled++;
    800021aa:	1c0ba783          	lw	a5,448(s7)
    800021ae:	2785                	addiw	a5,a5,1
    800021b0:	1cfba023          	sw	a5,448(s7)
        c->proc=t;
    800021b4:	037cb823          	sd	s7,48(s9)
        swtch(&c->context,&t->context);
    800021b8:	060b8593          	addi	a1,s7,96
    800021bc:	856a                	mv	a0,s10
    800021be:	00001097          	auipc	ra,0x1
    800021c2:	92e080e7          	jalr	-1746(ra) # 80002aec <swtch>
        c->proc=0;
    800021c6:	020cb823          	sd	zero,48(s9)
      release(&t->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	c62080e7          	jalr	-926(ra) # 80000e2e <release>
    800021d4:	a099                	j	8000221a <scheduler+0x11c>
    800021d6:	8ba6                	mv	s7,s1
    800021d8:	a011                	j	800021dc <scheduler+0xde>
    800021da:	8ba6                	mv	s7,s1
      release(&p->lock);
    800021dc:	8552                	mv	a0,s4
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	c50080e7          	jalr	-944(ra) # 80000e2e <release>
    for(p=proc;p<&proc[NPROC];p++)
    800021e6:	fb69f1e3          	bgeu	s3,s6,80002188 <scheduler+0x8a>
    800021ea:	1c848493          	addi	s1,s1,456
    800021ee:	1c890913          	addi	s2,s2,456
    800021f2:	8a26                	mv	s4,s1
      acquire(&p->lock);
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	b84080e7          	jalr	-1148(ra) # 80000d7a <acquire>
      if(p->state==RUNNABLE)
    800021fe:	89ca                	mv	s3,s2
    80002200:	e5092783          	lw	a5,-432(s2)
    80002204:	f55788e3          	beq	a5,s5,80002154 <scheduler+0x56>
      release(&p->lock);
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	c24080e7          	jalr	-988(ra) # 80000e2e <release>
    for(p=proc;p<&proc[NPROC];p++)
    80002212:	fd696ce3          	bltu	s2,s6,800021ea <scheduler+0xec>
    if(t!=0)
    80002216:	f60b99e3          	bnez	s7,80002188 <scheduler+0x8a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000221a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000221e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002222:	10079073          	csrw	sstatus,a5
    for(p=proc;p<&proc[NPROC];p++)
    80002226:	0022f497          	auipc	s1,0x22f
    8000222a:	dd248493          	addi	s1,s1,-558 # 80230ff8 <proc>
    8000222e:	0022f917          	auipc	s2,0x22f
    80002232:	f9290913          	addi	s2,s2,-110 # 802311c0 <proc+0x1c8>
    t = 0;
    80002236:	8be2                	mv	s7,s8
    80002238:	bf6d                	j	800021f2 <scheduler+0xf4>
    8000223a:	8ba6                	mv	s7,s1
    8000223c:	b745                	j	800021dc <scheduler+0xde>

000000008000223e <sched>:
{
    8000223e:	7179                	addi	sp,sp,-48
    80002240:	f406                	sd	ra,40(sp)
    80002242:	f022                	sd	s0,32(sp)
    80002244:	ec26                	sd	s1,24(sp)
    80002246:	e84a                	sd	s2,16(sp)
    80002248:	e44e                	sd	s3,8(sp)
    8000224a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000224c:	00000097          	auipc	ra,0x0
    80002250:	946080e7          	jalr	-1722(ra) # 80001b92 <myproc>
    80002254:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	aaa080e7          	jalr	-1366(ra) # 80000d00 <holding>
    8000225e:	c93d                	beqz	a0,800022d4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002260:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002262:	2781                	sext.w	a5,a5
    80002264:	079e                	slli	a5,a5,0x7
    80002266:	0022f717          	auipc	a4,0x22f
    8000226a:	96270713          	addi	a4,a4,-1694 # 80230bc8 <pid_lock>
    8000226e:	97ba                	add	a5,a5,a4
    80002270:	0a87a703          	lw	a4,168(a5)
    80002274:	4785                	li	a5,1
    80002276:	06f71763          	bne	a4,a5,800022e4 <sched+0xa6>
  if (p->state == RUNNING)
    8000227a:	4c98                	lw	a4,24(s1)
    8000227c:	4791                	li	a5,4
    8000227e:	06f70b63          	beq	a4,a5,800022f4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002282:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002286:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002288:	efb5                	bnez	a5,80002304 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000228a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000228c:	0022f917          	auipc	s2,0x22f
    80002290:	93c90913          	addi	s2,s2,-1732 # 80230bc8 <pid_lock>
    80002294:	2781                	sext.w	a5,a5
    80002296:	079e                	slli	a5,a5,0x7
    80002298:	97ca                	add	a5,a5,s2
    8000229a:	0ac7a983          	lw	s3,172(a5)
    8000229e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022a0:	2781                	sext.w	a5,a5
    800022a2:	079e                	slli	a5,a5,0x7
    800022a4:	0022f597          	auipc	a1,0x22f
    800022a8:	95c58593          	addi	a1,a1,-1700 # 80230c00 <cpus+0x8>
    800022ac:	95be                	add	a1,a1,a5
    800022ae:	06048513          	addi	a0,s1,96
    800022b2:	00001097          	auipc	ra,0x1
    800022b6:	83a080e7          	jalr	-1990(ra) # 80002aec <swtch>
    800022ba:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022bc:	2781                	sext.w	a5,a5
    800022be:	079e                	slli	a5,a5,0x7
    800022c0:	993e                	add	s2,s2,a5
    800022c2:	0b392623          	sw	s3,172(s2)
}
    800022c6:	70a2                	ld	ra,40(sp)
    800022c8:	7402                	ld	s0,32(sp)
    800022ca:	64e2                	ld	s1,24(sp)
    800022cc:	6942                	ld	s2,16(sp)
    800022ce:	69a2                	ld	s3,8(sp)
    800022d0:	6145                	addi	sp,sp,48
    800022d2:	8082                	ret
    panic("sched p->lock");
    800022d4:	00006517          	auipc	a0,0x6
    800022d8:	f6450513          	addi	a0,a0,-156 # 80008238 <digits+0x1f8>
    800022dc:	ffffe097          	auipc	ra,0xffffe
    800022e0:	264080e7          	jalr	612(ra) # 80000540 <panic>
    panic("sched locks");
    800022e4:	00006517          	auipc	a0,0x6
    800022e8:	f6450513          	addi	a0,a0,-156 # 80008248 <digits+0x208>
    800022ec:	ffffe097          	auipc	ra,0xffffe
    800022f0:	254080e7          	jalr	596(ra) # 80000540 <panic>
    panic("sched running");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	f6450513          	addi	a0,a0,-156 # 80008258 <digits+0x218>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	244080e7          	jalr	580(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002304:	00006517          	auipc	a0,0x6
    80002308:	f6450513          	addi	a0,a0,-156 # 80008268 <digits+0x228>
    8000230c:	ffffe097          	auipc	ra,0xffffe
    80002310:	234080e7          	jalr	564(ra) # 80000540 <panic>

0000000080002314 <yield>:
{
    80002314:	1101                	addi	sp,sp,-32
    80002316:	ec06                	sd	ra,24(sp)
    80002318:	e822                	sd	s0,16(sp)
    8000231a:	e426                	sd	s1,8(sp)
    8000231c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000231e:	00000097          	auipc	ra,0x0
    80002322:	874080e7          	jalr	-1932(ra) # 80001b92 <myproc>
    80002326:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	a52080e7          	jalr	-1454(ra) # 80000d7a <acquire>
  p->state = RUNNABLE;
    80002330:	478d                	li	a5,3
    80002332:	cc9c                	sw	a5,24(s1)
  sched();
    80002334:	00000097          	auipc	ra,0x0
    80002338:	f0a080e7          	jalr	-246(ra) # 8000223e <sched>
  release(&p->lock);
    8000233c:	8526                	mv	a0,s1
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	af0080e7          	jalr	-1296(ra) # 80000e2e <release>
}
    80002346:	60e2                	ld	ra,24(sp)
    80002348:	6442                	ld	s0,16(sp)
    8000234a:	64a2                	ld	s1,8(sp)
    8000234c:	6105                	addi	sp,sp,32
    8000234e:	8082                	ret

0000000080002350 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002350:	7179                	addi	sp,sp,-48
    80002352:	f406                	sd	ra,40(sp)
    80002354:	f022                	sd	s0,32(sp)
    80002356:	ec26                	sd	s1,24(sp)
    80002358:	e84a                	sd	s2,16(sp)
    8000235a:	e44e                	sd	s3,8(sp)
    8000235c:	1800                	addi	s0,sp,48
    8000235e:	89aa                	mv	s3,a0
    80002360:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002362:	00000097          	auipc	ra,0x0
    80002366:	830080e7          	jalr	-2000(ra) # 80001b92 <myproc>
    8000236a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	a0e080e7          	jalr	-1522(ra) # 80000d7a <acquire>
  release(lk);
    80002374:	854a                	mv	a0,s2
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	ab8080e7          	jalr	-1352(ra) # 80000e2e <release>

  // Go to sleep.
  p->chan = chan;
    8000237e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002382:	4789                	li	a5,2
    80002384:	cc9c                	sw	a5,24(s1)
  sched();
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	eb8080e7          	jalr	-328(ra) # 8000223e <sched>

  // Tidy up.
  p->chan = 0;
    8000238e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	a9a080e7          	jalr	-1382(ra) # 80000e2e <release>
  acquire(lk);
    8000239c:	854a                	mv	a0,s2
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	9dc080e7          	jalr	-1572(ra) # 80000d7a <acquire>
}
    800023a6:	70a2                	ld	ra,40(sp)
    800023a8:	7402                	ld	s0,32(sp)
    800023aa:	64e2                	ld	s1,24(sp)
    800023ac:	6942                	ld	s2,16(sp)
    800023ae:	69a2                	ld	s3,8(sp)
    800023b0:	6145                	addi	sp,sp,48
    800023b2:	8082                	ret

00000000800023b4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023b4:	7139                	addi	sp,sp,-64
    800023b6:	fc06                	sd	ra,56(sp)
    800023b8:	f822                	sd	s0,48(sp)
    800023ba:	f426                	sd	s1,40(sp)
    800023bc:	f04a                	sd	s2,32(sp)
    800023be:	ec4e                	sd	s3,24(sp)
    800023c0:	e852                	sd	s4,16(sp)
    800023c2:	e456                	sd	s5,8(sp)
    800023c4:	0080                	addi	s0,sp,64
    800023c6:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023c8:	0022f497          	auipc	s1,0x22f
    800023cc:	c3048493          	addi	s1,s1,-976 # 80230ff8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800023d0:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800023d2:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800023d4:	00236917          	auipc	s2,0x236
    800023d8:	e2490913          	addi	s2,s2,-476 # 802381f8 <tickslock>
    800023dc:	a811                	j	800023f0 <wakeup+0x3c>
      }
      release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	a4e080e7          	jalr	-1458(ra) # 80000e2e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023e8:	1c848493          	addi	s1,s1,456
    800023ec:	03248663          	beq	s1,s2,80002418 <wakeup+0x64>
    if (p != myproc())
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	7a2080e7          	jalr	1954(ra) # 80001b92 <myproc>
    800023f8:	fea488e3          	beq	s1,a0,800023e8 <wakeup+0x34>
      acquire(&p->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	97c080e7          	jalr	-1668(ra) # 80000d7a <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002406:	4c9c                	lw	a5,24(s1)
    80002408:	fd379be3          	bne	a5,s3,800023de <wakeup+0x2a>
    8000240c:	709c                	ld	a5,32(s1)
    8000240e:	fd4798e3          	bne	a5,s4,800023de <wakeup+0x2a>
        p->state = RUNNABLE;
    80002412:	0154ac23          	sw	s5,24(s1)
    80002416:	b7e1                	j	800023de <wakeup+0x2a>
    }
  }
}
    80002418:	70e2                	ld	ra,56(sp)
    8000241a:	7442                	ld	s0,48(sp)
    8000241c:	74a2                	ld	s1,40(sp)
    8000241e:	7902                	ld	s2,32(sp)
    80002420:	69e2                	ld	s3,24(sp)
    80002422:	6a42                	ld	s4,16(sp)
    80002424:	6aa2                	ld	s5,8(sp)
    80002426:	6121                	addi	sp,sp,64
    80002428:	8082                	ret

000000008000242a <reparent>:
{
    8000242a:	7179                	addi	sp,sp,-48
    8000242c:	f406                	sd	ra,40(sp)
    8000242e:	f022                	sd	s0,32(sp)
    80002430:	ec26                	sd	s1,24(sp)
    80002432:	e84a                	sd	s2,16(sp)
    80002434:	e44e                	sd	s3,8(sp)
    80002436:	e052                	sd	s4,0(sp)
    80002438:	1800                	addi	s0,sp,48
    8000243a:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000243c:	0022f497          	auipc	s1,0x22f
    80002440:	bbc48493          	addi	s1,s1,-1092 # 80230ff8 <proc>
      pp->parent = initproc;
    80002444:	00006a17          	auipc	s4,0x6
    80002448:	4f4a0a13          	addi	s4,s4,1268 # 80008938 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000244c:	00236997          	auipc	s3,0x236
    80002450:	dac98993          	addi	s3,s3,-596 # 802381f8 <tickslock>
    80002454:	a029                	j	8000245e <reparent+0x34>
    80002456:	1c848493          	addi	s1,s1,456
    8000245a:	01348d63          	beq	s1,s3,80002474 <reparent+0x4a>
    if (pp->parent == p)
    8000245e:	7c9c                	ld	a5,56(s1)
    80002460:	ff279be3          	bne	a5,s2,80002456 <reparent+0x2c>
      pp->parent = initproc;
    80002464:	000a3503          	ld	a0,0(s4)
    80002468:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000246a:	00000097          	auipc	ra,0x0
    8000246e:	f4a080e7          	jalr	-182(ra) # 800023b4 <wakeup>
    80002472:	b7d5                	j	80002456 <reparent+0x2c>
}
    80002474:	70a2                	ld	ra,40(sp)
    80002476:	7402                	ld	s0,32(sp)
    80002478:	64e2                	ld	s1,24(sp)
    8000247a:	6942                	ld	s2,16(sp)
    8000247c:	69a2                	ld	s3,8(sp)
    8000247e:	6a02                	ld	s4,0(sp)
    80002480:	6145                	addi	sp,sp,48
    80002482:	8082                	ret

0000000080002484 <exit>:
{
    80002484:	7179                	addi	sp,sp,-48
    80002486:	f406                	sd	ra,40(sp)
    80002488:	f022                	sd	s0,32(sp)
    8000248a:	ec26                	sd	s1,24(sp)
    8000248c:	e84a                	sd	s2,16(sp)
    8000248e:	e44e                	sd	s3,8(sp)
    80002490:	e052                	sd	s4,0(sp)
    80002492:	1800                	addi	s0,sp,48
    80002494:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	6fc080e7          	jalr	1788(ra) # 80001b92 <myproc>
    8000249e:	89aa                	mv	s3,a0
  if (p == initproc)
    800024a0:	00006797          	auipc	a5,0x6
    800024a4:	4987b783          	ld	a5,1176(a5) # 80008938 <initproc>
    800024a8:	0d050493          	addi	s1,a0,208
    800024ac:	15050913          	addi	s2,a0,336
    800024b0:	02a79363          	bne	a5,a0,800024d6 <exit+0x52>
    panic("init exiting");
    800024b4:	00006517          	auipc	a0,0x6
    800024b8:	dcc50513          	addi	a0,a0,-564 # 80008280 <digits+0x240>
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	084080e7          	jalr	132(ra) # 80000540 <panic>
      fileclose(f);
    800024c4:	00003097          	auipc	ra,0x3
    800024c8:	98a080e7          	jalr	-1654(ra) # 80004e4e <fileclose>
      p->ofile[fd] = 0;
    800024cc:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800024d0:	04a1                	addi	s1,s1,8
    800024d2:	01248563          	beq	s1,s2,800024dc <exit+0x58>
    if (p->ofile[fd])
    800024d6:	6088                	ld	a0,0(s1)
    800024d8:	f575                	bnez	a0,800024c4 <exit+0x40>
    800024da:	bfdd                	j	800024d0 <exit+0x4c>
  begin_op();
    800024dc:	00002097          	auipc	ra,0x2
    800024e0:	4aa080e7          	jalr	1194(ra) # 80004986 <begin_op>
  iput(p->cwd);
    800024e4:	1509b503          	ld	a0,336(s3)
    800024e8:	00002097          	auipc	ra,0x2
    800024ec:	c8c080e7          	jalr	-884(ra) # 80004174 <iput>
  end_op();
    800024f0:	00002097          	auipc	ra,0x2
    800024f4:	514080e7          	jalr	1300(ra) # 80004a04 <end_op>
  p->cwd = 0;
    800024f8:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024fc:	0022e497          	auipc	s1,0x22e
    80002500:	6e448493          	addi	s1,s1,1764 # 80230be0 <wait_lock>
    80002504:	8526                	mv	a0,s1
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	874080e7          	jalr	-1932(ra) # 80000d7a <acquire>
  reparent(p);
    8000250e:	854e                	mv	a0,s3
    80002510:	00000097          	auipc	ra,0x0
    80002514:	f1a080e7          	jalr	-230(ra) # 8000242a <reparent>
  wakeup(p->parent);
    80002518:	0389b503          	ld	a0,56(s3)
    8000251c:	00000097          	auipc	ra,0x0
    80002520:	e98080e7          	jalr	-360(ra) # 800023b4 <wakeup>
  acquire(&p->lock);
    80002524:	854e                	mv	a0,s3
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	854080e7          	jalr	-1964(ra) # 80000d7a <acquire>
  p->xstate = status;
    8000252e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002532:	4795                	li	a5,5
    80002534:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002538:	00006797          	auipc	a5,0x6
    8000253c:	4087a783          	lw	a5,1032(a5) # 80008940 <ticks>
    80002540:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002544:	8526                	mv	a0,s1
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	8e8080e7          	jalr	-1816(ra) # 80000e2e <release>
  sched();
    8000254e:	00000097          	auipc	ra,0x0
    80002552:	cf0080e7          	jalr	-784(ra) # 8000223e <sched>
  panic("zombie exit");
    80002556:	00006517          	auipc	a0,0x6
    8000255a:	d3a50513          	addi	a0,a0,-710 # 80008290 <digits+0x250>
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	fe2080e7          	jalr	-30(ra) # 80000540 <panic>

0000000080002566 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002566:	7179                	addi	sp,sp,-48
    80002568:	f406                	sd	ra,40(sp)
    8000256a:	f022                	sd	s0,32(sp)
    8000256c:	ec26                	sd	s1,24(sp)
    8000256e:	e84a                	sd	s2,16(sp)
    80002570:	e44e                	sd	s3,8(sp)
    80002572:	1800                	addi	s0,sp,48
    80002574:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002576:	0022f497          	auipc	s1,0x22f
    8000257a:	a8248493          	addi	s1,s1,-1406 # 80230ff8 <proc>
    8000257e:	00236997          	auipc	s3,0x236
    80002582:	c7a98993          	addi	s3,s3,-902 # 802381f8 <tickslock>
  {
    acquire(&p->lock);
    80002586:	8526                	mv	a0,s1
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	7f2080e7          	jalr	2034(ra) # 80000d7a <acquire>
    if (p->pid == pid)
    80002590:	589c                	lw	a5,48(s1)
    80002592:	01278d63          	beq	a5,s2,800025ac <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	896080e7          	jalr	-1898(ra) # 80000e2e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025a0:	1c848493          	addi	s1,s1,456
    800025a4:	ff3491e3          	bne	s1,s3,80002586 <kill+0x20>
  }
  return -1;
    800025a8:	557d                	li	a0,-1
    800025aa:	a829                	j	800025c4 <kill+0x5e>
      p->killed = 1;
    800025ac:	4785                	li	a5,1
    800025ae:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800025b0:	4c98                	lw	a4,24(s1)
    800025b2:	4789                	li	a5,2
    800025b4:	00f70f63          	beq	a4,a5,800025d2 <kill+0x6c>
      release(&p->lock);
    800025b8:	8526                	mv	a0,s1
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	874080e7          	jalr	-1932(ra) # 80000e2e <release>
      return 0;
    800025c2:	4501                	li	a0,0
}
    800025c4:	70a2                	ld	ra,40(sp)
    800025c6:	7402                	ld	s0,32(sp)
    800025c8:	64e2                	ld	s1,24(sp)
    800025ca:	6942                	ld	s2,16(sp)
    800025cc:	69a2                	ld	s3,8(sp)
    800025ce:	6145                	addi	sp,sp,48
    800025d0:	8082                	ret
        p->state = RUNNABLE;
    800025d2:	478d                	li	a5,3
    800025d4:	cc9c                	sw	a5,24(s1)
    800025d6:	b7cd                	j	800025b8 <kill+0x52>

00000000800025d8 <setkilled>:

void setkilled(struct proc *p)
{
    800025d8:	1101                	addi	sp,sp,-32
    800025da:	ec06                	sd	ra,24(sp)
    800025dc:	e822                	sd	s0,16(sp)
    800025de:	e426                	sd	s1,8(sp)
    800025e0:	1000                	addi	s0,sp,32
    800025e2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	796080e7          	jalr	1942(ra) # 80000d7a <acquire>
  p->killed = 1;
    800025ec:	4785                	li	a5,1
    800025ee:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	fffff097          	auipc	ra,0xfffff
    800025f6:	83c080e7          	jalr	-1988(ra) # 80000e2e <release>
}
    800025fa:	60e2                	ld	ra,24(sp)
    800025fc:	6442                	ld	s0,16(sp)
    800025fe:	64a2                	ld	s1,8(sp)
    80002600:	6105                	addi	sp,sp,32
    80002602:	8082                	ret

0000000080002604 <killed>:

int killed(struct proc *p)
{
    80002604:	1101                	addi	sp,sp,-32
    80002606:	ec06                	sd	ra,24(sp)
    80002608:	e822                	sd	s0,16(sp)
    8000260a:	e426                	sd	s1,8(sp)
    8000260c:	e04a                	sd	s2,0(sp)
    8000260e:	1000                	addi	s0,sp,32
    80002610:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	768080e7          	jalr	1896(ra) # 80000d7a <acquire>
  k = p->killed;
    8000261a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000261e:	8526                	mv	a0,s1
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	80e080e7          	jalr	-2034(ra) # 80000e2e <release>
  return k;
}
    80002628:	854a                	mv	a0,s2
    8000262a:	60e2                	ld	ra,24(sp)
    8000262c:	6442                	ld	s0,16(sp)
    8000262e:	64a2                	ld	s1,8(sp)
    80002630:	6902                	ld	s2,0(sp)
    80002632:	6105                	addi	sp,sp,32
    80002634:	8082                	ret

0000000080002636 <wait>:
{
    80002636:	715d                	addi	sp,sp,-80
    80002638:	e486                	sd	ra,72(sp)
    8000263a:	e0a2                	sd	s0,64(sp)
    8000263c:	fc26                	sd	s1,56(sp)
    8000263e:	f84a                	sd	s2,48(sp)
    80002640:	f44e                	sd	s3,40(sp)
    80002642:	f052                	sd	s4,32(sp)
    80002644:	ec56                	sd	s5,24(sp)
    80002646:	e85a                	sd	s6,16(sp)
    80002648:	e45e                	sd	s7,8(sp)
    8000264a:	e062                	sd	s8,0(sp)
    8000264c:	0880                	addi	s0,sp,80
    8000264e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	542080e7          	jalr	1346(ra) # 80001b92 <myproc>
    80002658:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000265a:	0022e517          	auipc	a0,0x22e
    8000265e:	58650513          	addi	a0,a0,1414 # 80230be0 <wait_lock>
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	718080e7          	jalr	1816(ra) # 80000d7a <acquire>
    havekids = 0;
    8000266a:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000266c:	4a15                	li	s4,5
        havekids = 1;
    8000266e:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002670:	00236997          	auipc	s3,0x236
    80002674:	b8898993          	addi	s3,s3,-1144 # 802381f8 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002678:	0022ec17          	auipc	s8,0x22e
    8000267c:	568c0c13          	addi	s8,s8,1384 # 80230be0 <wait_lock>
    havekids = 0;
    80002680:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002682:	0022f497          	auipc	s1,0x22f
    80002686:	97648493          	addi	s1,s1,-1674 # 80230ff8 <proc>
    8000268a:	a0bd                	j	800026f8 <wait+0xc2>
          pid = pp->pid;
    8000268c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002690:	000b0e63          	beqz	s6,800026ac <wait+0x76>
    80002694:	4691                	li	a3,4
    80002696:	02c48613          	addi	a2,s1,44
    8000269a:	85da                	mv	a1,s6
    8000269c:	05093503          	ld	a0,80(s2)
    800026a0:	fffff097          	auipc	ra,0xfffff
    800026a4:	17a080e7          	jalr	378(ra) # 8000181a <copyout>
    800026a8:	02054563          	bltz	a0,800026d2 <wait+0x9c>
          freeproc(pp);
    800026ac:	8526                	mv	a0,s1
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	696080e7          	jalr	1686(ra) # 80001d44 <freeproc>
          release(&pp->lock);
    800026b6:	8526                	mv	a0,s1
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	776080e7          	jalr	1910(ra) # 80000e2e <release>
          release(&wait_lock);
    800026c0:	0022e517          	auipc	a0,0x22e
    800026c4:	52050513          	addi	a0,a0,1312 # 80230be0 <wait_lock>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	766080e7          	jalr	1894(ra) # 80000e2e <release>
          return pid;
    800026d0:	a0b5                	j	8000273c <wait+0x106>
            release(&pp->lock);
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	75a080e7          	jalr	1882(ra) # 80000e2e <release>
            release(&wait_lock);
    800026dc:	0022e517          	auipc	a0,0x22e
    800026e0:	50450513          	addi	a0,a0,1284 # 80230be0 <wait_lock>
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	74a080e7          	jalr	1866(ra) # 80000e2e <release>
            return -1;
    800026ec:	59fd                	li	s3,-1
    800026ee:	a0b9                	j	8000273c <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f0:	1c848493          	addi	s1,s1,456
    800026f4:	03348463          	beq	s1,s3,8000271c <wait+0xe6>
      if (pp->parent == p)
    800026f8:	7c9c                	ld	a5,56(s1)
    800026fa:	ff279be3          	bne	a5,s2,800026f0 <wait+0xba>
        acquire(&pp->lock);
    800026fe:	8526                	mv	a0,s1
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	67a080e7          	jalr	1658(ra) # 80000d7a <acquire>
        if (pp->state == ZOMBIE)
    80002708:	4c9c                	lw	a5,24(s1)
    8000270a:	f94781e3          	beq	a5,s4,8000268c <wait+0x56>
        release(&pp->lock);
    8000270e:	8526                	mv	a0,s1
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	71e080e7          	jalr	1822(ra) # 80000e2e <release>
        havekids = 1;
    80002718:	8756                	mv	a4,s5
    8000271a:	bfd9                	j	800026f0 <wait+0xba>
    if (!havekids || killed(p))
    8000271c:	c719                	beqz	a4,8000272a <wait+0xf4>
    8000271e:	854a                	mv	a0,s2
    80002720:	00000097          	auipc	ra,0x0
    80002724:	ee4080e7          	jalr	-284(ra) # 80002604 <killed>
    80002728:	c51d                	beqz	a0,80002756 <wait+0x120>
      release(&wait_lock);
    8000272a:	0022e517          	auipc	a0,0x22e
    8000272e:	4b650513          	addi	a0,a0,1206 # 80230be0 <wait_lock>
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	6fc080e7          	jalr	1788(ra) # 80000e2e <release>
      return -1;
    8000273a:	59fd                	li	s3,-1
}
    8000273c:	854e                	mv	a0,s3
    8000273e:	60a6                	ld	ra,72(sp)
    80002740:	6406                	ld	s0,64(sp)
    80002742:	74e2                	ld	s1,56(sp)
    80002744:	7942                	ld	s2,48(sp)
    80002746:	79a2                	ld	s3,40(sp)
    80002748:	7a02                	ld	s4,32(sp)
    8000274a:	6ae2                	ld	s5,24(sp)
    8000274c:	6b42                	ld	s6,16(sp)
    8000274e:	6ba2                	ld	s7,8(sp)
    80002750:	6c02                	ld	s8,0(sp)
    80002752:	6161                	addi	sp,sp,80
    80002754:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002756:	85e2                	mv	a1,s8
    80002758:	854a                	mv	a0,s2
    8000275a:	00000097          	auipc	ra,0x0
    8000275e:	bf6080e7          	jalr	-1034(ra) # 80002350 <sleep>
    havekids = 0;
    80002762:	bf39                	j	80002680 <wait+0x4a>

0000000080002764 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002764:	7179                	addi	sp,sp,-48
    80002766:	f406                	sd	ra,40(sp)
    80002768:	f022                	sd	s0,32(sp)
    8000276a:	ec26                	sd	s1,24(sp)
    8000276c:	e84a                	sd	s2,16(sp)
    8000276e:	e44e                	sd	s3,8(sp)
    80002770:	e052                	sd	s4,0(sp)
    80002772:	1800                	addi	s0,sp,48
    80002774:	84aa                	mv	s1,a0
    80002776:	892e                	mv	s2,a1
    80002778:	89b2                	mv	s3,a2
    8000277a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000277c:	fffff097          	auipc	ra,0xfffff
    80002780:	416080e7          	jalr	1046(ra) # 80001b92 <myproc>
  if (user_dst)
    80002784:	c08d                	beqz	s1,800027a6 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002786:	86d2                	mv	a3,s4
    80002788:	864e                	mv	a2,s3
    8000278a:	85ca                	mv	a1,s2
    8000278c:	6928                	ld	a0,80(a0)
    8000278e:	fffff097          	auipc	ra,0xfffff
    80002792:	08c080e7          	jalr	140(ra) # 8000181a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002796:	70a2                	ld	ra,40(sp)
    80002798:	7402                	ld	s0,32(sp)
    8000279a:	64e2                	ld	s1,24(sp)
    8000279c:	6942                	ld	s2,16(sp)
    8000279e:	69a2                	ld	s3,8(sp)
    800027a0:	6a02                	ld	s4,0(sp)
    800027a2:	6145                	addi	sp,sp,48
    800027a4:	8082                	ret
    memmove((char *)dst, src, len);
    800027a6:	000a061b          	sext.w	a2,s4
    800027aa:	85ce                	mv	a1,s3
    800027ac:	854a                	mv	a0,s2
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	724080e7          	jalr	1828(ra) # 80000ed2 <memmove>
    return 0;
    800027b6:	8526                	mv	a0,s1
    800027b8:	bff9                	j	80002796 <either_copyout+0x32>

00000000800027ba <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027ba:	7179                	addi	sp,sp,-48
    800027bc:	f406                	sd	ra,40(sp)
    800027be:	f022                	sd	s0,32(sp)
    800027c0:	ec26                	sd	s1,24(sp)
    800027c2:	e84a                	sd	s2,16(sp)
    800027c4:	e44e                	sd	s3,8(sp)
    800027c6:	e052                	sd	s4,0(sp)
    800027c8:	1800                	addi	s0,sp,48
    800027ca:	892a                	mv	s2,a0
    800027cc:	84ae                	mv	s1,a1
    800027ce:	89b2                	mv	s3,a2
    800027d0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027d2:	fffff097          	auipc	ra,0xfffff
    800027d6:	3c0080e7          	jalr	960(ra) # 80001b92 <myproc>
  if (user_src)
    800027da:	c08d                	beqz	s1,800027fc <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027dc:	86d2                	mv	a3,s4
    800027de:	864e                	mv	a2,s3
    800027e0:	85ca                	mv	a1,s2
    800027e2:	6928                	ld	a0,80(a0)
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	0fa080e7          	jalr	250(ra) # 800018de <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800027ec:	70a2                	ld	ra,40(sp)
    800027ee:	7402                	ld	s0,32(sp)
    800027f0:	64e2                	ld	s1,24(sp)
    800027f2:	6942                	ld	s2,16(sp)
    800027f4:	69a2                	ld	s3,8(sp)
    800027f6:	6a02                	ld	s4,0(sp)
    800027f8:	6145                	addi	sp,sp,48
    800027fa:	8082                	ret
    memmove(dst, (char *)src, len);
    800027fc:	000a061b          	sext.w	a2,s4
    80002800:	85ce                	mv	a1,s3
    80002802:	854a                	mv	a0,s2
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	6ce080e7          	jalr	1742(ra) # 80000ed2 <memmove>
    return 0;
    8000280c:	8526                	mv	a0,s1
    8000280e:	bff9                	j	800027ec <either_copyin+0x32>

0000000080002810 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002810:	7139                	addi	sp,sp,-64
    80002812:	fc06                	sd	ra,56(sp)
    80002814:	f822                	sd	s0,48(sp)
    80002816:	f426                	sd	s1,40(sp)
    80002818:	f04a                	sd	s2,32(sp)
    8000281a:	ec4e                	sd	s3,24(sp)
    8000281c:	e852                	sd	s4,16(sp)
    8000281e:	e456                	sd	s5,8(sp)
    80002820:	e05a                	sd	s6,0(sp)
    80002822:	0080                	addi	s0,sp,64
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  for (p = proc; p < &proc[NPROC]; p++)
    80002824:	0022f497          	auipc	s1,0x22f
    80002828:	92c48493          	addi	s1,s1,-1748 # 80231150 <proc+0x158>
    8000282c:	00236917          	auipc	s2,0x236
    80002830:	b2490913          	addi	s2,s2,-1244 # 80238350 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002834:	4a95                	li	s5,5
      state = states[p->state];
    else
      state = "???";
    80002836:	00006997          	auipc	s3,0x6
    8000283a:	a6a98993          	addi	s3,s3,-1430 # 800082a0 <digits+0x260>
    printf("%d %s %s\n", p->pid, state, p->name);
    8000283e:	00006a17          	auipc	s4,0x6
    80002842:	a6aa0a13          	addi	s4,s4,-1430 # 800082a8 <digits+0x268>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002846:	00006b17          	auipc	s6,0x6
    8000284a:	aa2b0b13          	addi	s6,s6,-1374 # 800082e8 <states.0>
    8000284e:	a821                	j	80002866 <procdump+0x56>
    printf("%d %s %s\n", p->pid, state, p->name);
    80002850:	ed86a583          	lw	a1,-296(a3)
    80002854:	8552                	mv	a0,s4
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	d34080e7          	jalr	-716(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000285e:	1c848493          	addi	s1,s1,456
    80002862:	03248263          	beq	s1,s2,80002886 <procdump+0x76>
    if (p->state == UNUSED)
    80002866:	86a6                	mv	a3,s1
    80002868:	ec04a783          	lw	a5,-320(s1)
    8000286c:	dbed                	beqz	a5,8000285e <procdump+0x4e>
      state = "???";
    8000286e:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002870:	fefae0e3          	bltu	s5,a5,80002850 <procdump+0x40>
    80002874:	02079713          	slli	a4,a5,0x20
    80002878:	01d75793          	srli	a5,a4,0x1d
    8000287c:	97da                	add	a5,a5,s6
    8000287e:	6390                	ld	a2,0(a5)
    80002880:	fa61                	bnez	a2,80002850 <procdump+0x40>
      state = "???";
    80002882:	864e                	mv	a2,s3
    80002884:	b7f1                	j	80002850 <procdump+0x40>
  }
}
    80002886:	70e2                	ld	ra,56(sp)
    80002888:	7442                	ld	s0,48(sp)
    8000288a:	74a2                	ld	s1,40(sp)
    8000288c:	7902                	ld	s2,32(sp)
    8000288e:	69e2                	ld	s3,24(sp)
    80002890:	6a42                	ld	s4,16(sp)
    80002892:	6aa2                	ld	s5,8(sp)
    80002894:	6b02                	ld	s6,0(sp)
    80002896:	6121                	addi	sp,sp,64
    80002898:	8082                	ret

000000008000289a <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000289a:	711d                	addi	sp,sp,-96
    8000289c:	ec86                	sd	ra,88(sp)
    8000289e:	e8a2                	sd	s0,80(sp)
    800028a0:	e4a6                	sd	s1,72(sp)
    800028a2:	e0ca                	sd	s2,64(sp)
    800028a4:	fc4e                	sd	s3,56(sp)
    800028a6:	f852                	sd	s4,48(sp)
    800028a8:	f456                	sd	s5,40(sp)
    800028aa:	f05a                	sd	s6,32(sp)
    800028ac:	ec5e                	sd	s7,24(sp)
    800028ae:	e862                	sd	s8,16(sp)
    800028b0:	e466                	sd	s9,8(sp)
    800028b2:	e06a                	sd	s10,0(sp)
    800028b4:	1080                	addi	s0,sp,96
    800028b6:	8b2a                	mv	s6,a0
    800028b8:	8bae                	mv	s7,a1
    800028ba:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800028bc:	fffff097          	auipc	ra,0xfffff
    800028c0:	2d6080e7          	jalr	726(ra) # 80001b92 <myproc>
    800028c4:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800028c6:	0022e517          	auipc	a0,0x22e
    800028ca:	31a50513          	addi	a0,a0,794 # 80230be0 <wait_lock>
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	4ac080e7          	jalr	1196(ra) # 80000d7a <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800028d6:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800028d8:	4a15                	li	s4,5
        havekids = 1;
    800028da:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800028dc:	00236997          	auipc	s3,0x236
    800028e0:	91c98993          	addi	s3,s3,-1764 # 802381f8 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028e4:	0022ed17          	auipc	s10,0x22e
    800028e8:	2fcd0d13          	addi	s10,s10,764 # 80230be0 <wait_lock>
    havekids = 0;
    800028ec:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800028ee:	0022e497          	auipc	s1,0x22e
    800028f2:	70a48493          	addi	s1,s1,1802 # 80230ff8 <proc>
    800028f6:	a059                	j	8000297c <waitx+0xe2>
          pid = np->pid;
    800028f8:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800028fc:	1684a783          	lw	a5,360(s1)
    80002900:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002904:	16c4a703          	lw	a4,364(s1)
    80002908:	9f3d                	addw	a4,a4,a5
    8000290a:	1704a783          	lw	a5,368(s1)
    8000290e:	9f99                	subw	a5,a5,a4
    80002910:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002914:	000b0e63          	beqz	s6,80002930 <waitx+0x96>
    80002918:	4691                	li	a3,4
    8000291a:	02c48613          	addi	a2,s1,44
    8000291e:	85da                	mv	a1,s6
    80002920:	05093503          	ld	a0,80(s2)
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	ef6080e7          	jalr	-266(ra) # 8000181a <copyout>
    8000292c:	02054563          	bltz	a0,80002956 <waitx+0xbc>
          freeproc(np);
    80002930:	8526                	mv	a0,s1
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	412080e7          	jalr	1042(ra) # 80001d44 <freeproc>
          release(&np->lock);
    8000293a:	8526                	mv	a0,s1
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	4f2080e7          	jalr	1266(ra) # 80000e2e <release>
          release(&wait_lock);
    80002944:	0022e517          	auipc	a0,0x22e
    80002948:	29c50513          	addi	a0,a0,668 # 80230be0 <wait_lock>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	4e2080e7          	jalr	1250(ra) # 80000e2e <release>
          return pid;
    80002954:	a09d                	j	800029ba <waitx+0x120>
            release(&np->lock);
    80002956:	8526                	mv	a0,s1
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	4d6080e7          	jalr	1238(ra) # 80000e2e <release>
            release(&wait_lock);
    80002960:	0022e517          	auipc	a0,0x22e
    80002964:	28050513          	addi	a0,a0,640 # 80230be0 <wait_lock>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	4c6080e7          	jalr	1222(ra) # 80000e2e <release>
            return -1;
    80002970:	59fd                	li	s3,-1
    80002972:	a0a1                	j	800029ba <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002974:	1c848493          	addi	s1,s1,456
    80002978:	03348463          	beq	s1,s3,800029a0 <waitx+0x106>
      if (np->parent == p)
    8000297c:	7c9c                	ld	a5,56(s1)
    8000297e:	ff279be3          	bne	a5,s2,80002974 <waitx+0xda>
        acquire(&np->lock);
    80002982:	8526                	mv	a0,s1
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	3f6080e7          	jalr	1014(ra) # 80000d7a <acquire>
        if (np->state == ZOMBIE)
    8000298c:	4c9c                	lw	a5,24(s1)
    8000298e:	f74785e3          	beq	a5,s4,800028f8 <waitx+0x5e>
        release(&np->lock);
    80002992:	8526                	mv	a0,s1
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	49a080e7          	jalr	1178(ra) # 80000e2e <release>
        havekids = 1;
    8000299c:	8756                	mv	a4,s5
    8000299e:	bfd9                	j	80002974 <waitx+0xda>
    if (!havekids || p->killed)
    800029a0:	c701                	beqz	a4,800029a8 <waitx+0x10e>
    800029a2:	02892783          	lw	a5,40(s2)
    800029a6:	cb8d                	beqz	a5,800029d8 <waitx+0x13e>
      release(&wait_lock);
    800029a8:	0022e517          	auipc	a0,0x22e
    800029ac:	23850513          	addi	a0,a0,568 # 80230be0 <wait_lock>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	47e080e7          	jalr	1150(ra) # 80000e2e <release>
      return -1;
    800029b8:	59fd                	li	s3,-1
  }
}
    800029ba:	854e                	mv	a0,s3
    800029bc:	60e6                	ld	ra,88(sp)
    800029be:	6446                	ld	s0,80(sp)
    800029c0:	64a6                	ld	s1,72(sp)
    800029c2:	6906                	ld	s2,64(sp)
    800029c4:	79e2                	ld	s3,56(sp)
    800029c6:	7a42                	ld	s4,48(sp)
    800029c8:	7aa2                	ld	s5,40(sp)
    800029ca:	7b02                	ld	s6,32(sp)
    800029cc:	6be2                	ld	s7,24(sp)
    800029ce:	6c42                	ld	s8,16(sp)
    800029d0:	6ca2                	ld	s9,8(sp)
    800029d2:	6d02                	ld	s10,0(sp)
    800029d4:	6125                	addi	sp,sp,96
    800029d6:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800029d8:	85ea                	mv	a1,s10
    800029da:	854a                	mv	a0,s2
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	974080e7          	jalr	-1676(ra) # 80002350 <sleep>
    havekids = 0;
    800029e4:	b721                	j	800028ec <waitx+0x52>

00000000800029e6 <update_time>:

void update_time()
{
    800029e6:	715d                	addi	sp,sp,-80
    800029e8:	e486                	sd	ra,72(sp)
    800029ea:	e0a2                	sd	s0,64(sp)
    800029ec:	fc26                	sd	s1,56(sp)
    800029ee:	f84a                	sd	s2,48(sp)
    800029f0:	f44e                	sd	s3,40(sp)
    800029f2:	f052                	sd	s4,32(sp)
    800029f4:	ec56                	sd	s5,24(sp)
    800029f6:	e85a                	sd	s6,16(sp)
    800029f8:	e45e                	sd	s7,8(sp)
    800029fa:	0880                	addi	s0,sp,80
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800029fc:	0022e497          	auipc	s1,0x22e
    80002a00:	5fc48493          	addi	s1,s1,1532 # 80230ff8 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002a04:	4a91                	li	s5,4
    #ifdef PBS
    if(p->hastosleep)
    {
      p->stime++;
    }
    else if(p->state==RUNNABLE)
    80002a06:	4b8d                	li	s7,3
    {
      p->wtime++;
    }
    float t= ((float)(3*p->runtime-p->stime-p->wtime)/(p->runtime+p->wtime+p->stime+1))*50.0;
    80002a08:	00005a17          	auipc	s4,0x5
    80002a0c:	600a0a13          	addi	s4,s4,1536 # 80008008 <etext+0x8>
    80002a10:	06400993          	li	s3,100
    80002a14:	06400b13          	li	s6,100
  for (p = proc; p < &proc[NPROC]; p++)
    80002a18:	00235917          	auipc	s2,0x235
    80002a1c:	7e090913          	addi	s2,s2,2016 # 802381f8 <tickslock>
    80002a20:	a841                	j	80002ab0 <update_time+0xca>
      p->rtime++;
    80002a22:	1684a783          	lw	a5,360(s1)
    80002a26:	2785                	addiw	a5,a5,1
    80002a28:	16f4a423          	sw	a5,360(s1)
      p->runtime++;
    80002a2c:	1bc4a783          	lw	a5,444(s1)
    80002a30:	2785                	addiw	a5,a5,1
    80002a32:	1af4ae23          	sw	a5,444(s1)
    if(p->hastosleep)
    80002a36:	1b04a783          	lw	a5,432(s1)
    80002a3a:	c791                	beqz	a5,80002a46 <update_time+0x60>
      p->stime++;
    80002a3c:	1c44a783          	lw	a5,452(s1)
    80002a40:	2785                	addiw	a5,a5,1
    80002a42:	1cf4a223          	sw	a5,452(s1)
    float t= ((float)(3*p->runtime-p->stime-p->wtime)/(p->runtime+p->wtime+p->stime+1))*50.0;
    80002a46:	1bc4a783          	lw	a5,444(s1)
    80002a4a:	1c44a683          	lw	a3,452(s1)
    80002a4e:	1ac4a603          	lw	a2,428(s1)
    80002a52:	0017971b          	slliw	a4,a5,0x1
    80002a56:	9f3d                	addw	a4,a4,a5
    80002a58:	9f15                	subw	a4,a4,a3
    80002a5a:	9f11                	subw	a4,a4,a2
    80002a5c:	d00777d3          	fcvt.s.w	fa5,a4
    80002a60:	9fb1                	addw	a5,a5,a2
    80002a62:	9fb5                	addw	a5,a5,a3
    80002a64:	2785                	addiw	a5,a5,1
    80002a66:	d007f753          	fcvt.s.w	fa4,a5
    80002a6a:	18e7f7d3          	fdiv.s	fa5,fa5,fa4
    80002a6e:	000a2707          	flw	fa4,0(s4)
    80002a72:	10e7f7d3          	fmul.s	fa5,fa5,fa4
    p->rbi=t;
    80002a76:	c00797d3          	fcvt.w.s	a5,fa5,rtz
    80002a7a:	0007871b          	sext.w	a4,a5
    80002a7e:	fff74713          	not	a4,a4
    80002a82:	977d                	srai	a4,a4,0x3f
    80002a84:	8ff9                	and	a5,a5,a4
    80002a86:	1af4aa23          	sw	a5,436(s1)
    if(p->rbi<0.0)
    {
      p->rbi=0;
    }   
    if(p->priority+p->rbi>100)
    80002a8a:	1a44a703          	lw	a4,420(s1)
    80002a8e:	9fb9                	addw	a5,a5,a4
    80002a90:	0007871b          	sext.w	a4,a5
    80002a94:	00e9d363          	bge	s3,a4,80002a9a <update_time+0xb4>
    80002a98:	87da                	mv	a5,s6
    80002a9a:	1af4ac23          	sw	a5,440(s1)
    else
    {
      p->dp=p->priority+p->rbi;
    }
    #endif
    release(&p->lock);
    80002a9e:	8526                	mv	a0,s1
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	38e080e7          	jalr	910(ra) # 80000e2e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002aa8:	1c848493          	addi	s1,s1,456
    80002aac:	03248563          	beq	s1,s2,80002ad6 <update_time+0xf0>
    acquire(&p->lock);
    80002ab0:	8526                	mv	a0,s1
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	2c8080e7          	jalr	712(ra) # 80000d7a <acquire>
    if (p->state == RUNNING)
    80002aba:	4c9c                	lw	a5,24(s1)
    80002abc:	f75783e3          	beq	a5,s5,80002a22 <update_time+0x3c>
    if(p->hastosleep)
    80002ac0:	1b04a703          	lw	a4,432(s1)
    80002ac4:	ff25                	bnez	a4,80002a3c <update_time+0x56>
    else if(p->state==RUNNABLE)
    80002ac6:	f97790e3          	bne	a5,s7,80002a46 <update_time+0x60>
      p->wtime++;
    80002aca:	1ac4a783          	lw	a5,428(s1)
    80002ace:	2785                	addiw	a5,a5,1
    80002ad0:	1af4a623          	sw	a5,428(s1)
    80002ad4:	bf8d                	j	80002a46 <update_time+0x60>
  }
    80002ad6:	60a6                	ld	ra,72(sp)
    80002ad8:	6406                	ld	s0,64(sp)
    80002ada:	74e2                	ld	s1,56(sp)
    80002adc:	7942                	ld	s2,48(sp)
    80002ade:	79a2                	ld	s3,40(sp)
    80002ae0:	7a02                	ld	s4,32(sp)
    80002ae2:	6ae2                	ld	s5,24(sp)
    80002ae4:	6b42                	ld	s6,16(sp)
    80002ae6:	6ba2                	ld	s7,8(sp)
    80002ae8:	6161                	addi	sp,sp,80
    80002aea:	8082                	ret

0000000080002aec <swtch>:
    80002aec:	00153023          	sd	ra,0(a0)
    80002af0:	00253423          	sd	sp,8(a0)
    80002af4:	e900                	sd	s0,16(a0)
    80002af6:	ed04                	sd	s1,24(a0)
    80002af8:	03253023          	sd	s2,32(a0)
    80002afc:	03353423          	sd	s3,40(a0)
    80002b00:	03453823          	sd	s4,48(a0)
    80002b04:	03553c23          	sd	s5,56(a0)
    80002b08:	05653023          	sd	s6,64(a0)
    80002b0c:	05753423          	sd	s7,72(a0)
    80002b10:	05853823          	sd	s8,80(a0)
    80002b14:	05953c23          	sd	s9,88(a0)
    80002b18:	07a53023          	sd	s10,96(a0)
    80002b1c:	07b53423          	sd	s11,104(a0)
    80002b20:	0005b083          	ld	ra,0(a1)
    80002b24:	0085b103          	ld	sp,8(a1)
    80002b28:	6980                	ld	s0,16(a1)
    80002b2a:	6d84                	ld	s1,24(a1)
    80002b2c:	0205b903          	ld	s2,32(a1)
    80002b30:	0285b983          	ld	s3,40(a1)
    80002b34:	0305ba03          	ld	s4,48(a1)
    80002b38:	0385ba83          	ld	s5,56(a1)
    80002b3c:	0405bb03          	ld	s6,64(a1)
    80002b40:	0485bb83          	ld	s7,72(a1)
    80002b44:	0505bc03          	ld	s8,80(a1)
    80002b48:	0585bc83          	ld	s9,88(a1)
    80002b4c:	0605bd03          	ld	s10,96(a1)
    80002b50:	0685bd83          	ld	s11,104(a1)
    80002b54:	8082                	ret

0000000080002b56 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b56:	1141                	addi	sp,sp,-16
    80002b58:	e406                	sd	ra,8(sp)
    80002b5a:	e022                	sd	s0,0(sp)
    80002b5c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b5e:	00005597          	auipc	a1,0x5
    80002b62:	7ba58593          	addi	a1,a1,1978 # 80008318 <states.0+0x30>
    80002b66:	00235517          	auipc	a0,0x235
    80002b6a:	69250513          	addi	a0,a0,1682 # 802381f8 <tickslock>
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	17c080e7          	jalr	380(ra) # 80000cea <initlock>
}
    80002b76:	60a2                	ld	ra,8(sp)
    80002b78:	6402                	ld	s0,0(sp)
    80002b7a:	0141                	addi	sp,sp,16
    80002b7c:	8082                	ret

0000000080002b7e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b7e:	1141                	addi	sp,sp,-16
    80002b80:	e422                	sd	s0,8(sp)
    80002b82:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b84:	00004797          	auipc	a5,0x4
    80002b88:	91c78793          	addi	a5,a5,-1764 # 800064a0 <kernelvec>
    80002b8c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b90:	6422                	ld	s0,8(sp)
    80002b92:	0141                	addi	sp,sp,16
    80002b94:	8082                	ret

0000000080002b96 <PageFaultHandler>:
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//

int PageFaultHandler(void *va, pagetable_t pagetable)
{
    80002b96:	7179                	addi	sp,sp,-48
    80002b98:	f406                	sd	ra,40(sp)
    80002b9a:	f022                	sd	s0,32(sp)
    80002b9c:	ec26                	sd	s1,24(sp)
    80002b9e:	e84a                	sd	s2,16(sp)
    80002ba0:	e44e                	sd	s3,8(sp)
    80002ba2:	1800                	addi	s0,sp,48
    80002ba4:	84aa                	mv	s1,a0
    80002ba6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	fea080e7          	jalr	-22(ra) # 80001b92 <myproc>
  pte_t *pte;
  uint flags;
  uint64 val = PGROUNDDOWN(p->trapframe->sp);
    80002bb0:	6d3c                	ld	a5,88(a0)
    80002bb2:	7b98                	ld	a4,48(a5)
    80002bb4:	77fd                	lui	a5,0xfffff
    80002bb6:	8ff9                	and	a5,a5,a4
  if ((uint64)va >= MAXVA || ((uint64)va <= val && (uint64)va >= val - PGSIZE))
    80002bb8:	577d                	li	a4,-1
    80002bba:	8369                	srli	a4,a4,0x1a
    80002bbc:	06976e63          	bltu	a4,s1,80002c38 <PageFaultHandler+0xa2>
    80002bc0:	0097e663          	bltu	a5,s1,80002bcc <PageFaultHandler+0x36>
    80002bc4:	777d                	lui	a4,0xfffff
    80002bc6:	97ba                	add	a5,a5,a4
    80002bc8:	06f4fa63          	bgeu	s1,a5,80002c3c <PageFaultHandler+0xa6>
  {
    return -1;
  }
  pte = walk(pagetable, (uint64)va, 0);
    80002bcc:	4601                	li	a2,0
    80002bce:	85a6                	mv	a1,s1
    80002bd0:	854a                	mv	a0,s2
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	588080e7          	jalr	1416(ra) # 8000115a <walk>
    80002bda:	84aa                	mv	s1,a0
  if (!pte)
    80002bdc:	c135                	beqz	a0,80002c40 <PageFaultHandler+0xaa>
  {
    return -1;
  }
  va = (void *)PGROUNDDOWN((uint64)va);
  flags = PTE_FLAGS(*pte);
    80002bde:	411c                	lw	a5,0(a0)
  if (flags & PTE_COW)
    80002be0:	1007f713          	andi	a4,a5,256
    *pte = PA2PTE(mem) | flags;
    return 0;
  }
  else
  {
    return 0;
    80002be4:	4501                	li	a0,0
  if (flags & PTE_COW)
    80002be6:	eb01                	bnez	a4,80002bf6 <PageFaultHandler+0x60>
  }
}
    80002be8:	70a2                	ld	ra,40(sp)
    80002bea:	7402                	ld	s0,32(sp)
    80002bec:	64e2                	ld	s1,24(sp)
    80002bee:	6942                	ld	s2,16(sp)
    80002bf0:	69a2                	ld	s3,8(sp)
    80002bf2:	6145                	addi	sp,sp,48
    80002bf4:	8082                	ret
    flags &= (~PTE_COW);
    80002bf6:	2ff7f793          	andi	a5,a5,767
    80002bfa:	0047e913          	ori	s2,a5,4
    char *mem = (char *)kalloc();
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	078080e7          	jalr	120(ra) # 80000c76 <kalloc>
    80002c06:	89aa                	mv	s3,a0
    if (!mem)
    80002c08:	cd15                	beqz	a0,80002c44 <PageFaultHandler+0xae>
    memmove(mem, (void *)PTE2PA(*pte), PGSIZE);
    80002c0a:	608c                	ld	a1,0(s1)
    80002c0c:	81a9                	srli	a1,a1,0xa
    80002c0e:	6605                	lui	a2,0x1
    80002c10:	05b2                	slli	a1,a1,0xc
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	2c0080e7          	jalr	704(ra) # 80000ed2 <memmove>
    kfree((void *)PTE2PA(*pte));
    80002c1a:	6088                	ld	a0,0(s1)
    80002c1c:	8129                	srli	a0,a0,0xa
    80002c1e:	0532                	slli	a0,a0,0xc
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	f14080e7          	jalr	-236(ra) # 80000b34 <kfree>
    *pte = PA2PTE(mem) | flags;
    80002c28:	00c9d993          	srli	s3,s3,0xc
    80002c2c:	09aa                	slli	s3,s3,0xa
    80002c2e:	013967b3          	or	a5,s2,s3
    80002c32:	e09c                	sd	a5,0(s1)
    return 0;
    80002c34:	4501                	li	a0,0
    80002c36:	bf4d                	j	80002be8 <PageFaultHandler+0x52>
    return -1;
    80002c38:	557d                	li	a0,-1
    80002c3a:	b77d                	j	80002be8 <PageFaultHandler+0x52>
    80002c3c:	557d                	li	a0,-1
    80002c3e:	b76d                	j	80002be8 <PageFaultHandler+0x52>
    return -1;
    80002c40:	557d                	li	a0,-1
    80002c42:	b75d                	j	80002be8 <PageFaultHandler+0x52>
      return -1;
    80002c44:	557d                	li	a0,-1
    80002c46:	b74d                	j	80002be8 <PageFaultHandler+0x52>

0000000080002c48 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002c48:	1141                	addi	sp,sp,-16
    80002c4a:	e406                	sd	ra,8(sp)
    80002c4c:	e022                	sd	s0,0(sp)
    80002c4e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	f42080e7          	jalr	-190(ra) # 80001b92 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c5c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c5e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c62:	00004697          	auipc	a3,0x4
    80002c66:	39e68693          	addi	a3,a3,926 # 80007000 <_trampoline>
    80002c6a:	00004717          	auipc	a4,0x4
    80002c6e:	39670713          	addi	a4,a4,918 # 80007000 <_trampoline>
    80002c72:	8f15                	sub	a4,a4,a3
    80002c74:	040007b7          	lui	a5,0x4000
    80002c78:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002c7a:	07b2                	slli	a5,a5,0xc
    80002c7c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c7e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c82:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c84:	18002673          	csrr	a2,satp
    80002c88:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c8a:	6d30                	ld	a2,88(a0)
    80002c8c:	6138                	ld	a4,64(a0)
    80002c8e:	6585                	lui	a1,0x1
    80002c90:	972e                	add	a4,a4,a1
    80002c92:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c94:	6d38                	ld	a4,88(a0)
    80002c96:	00000617          	auipc	a2,0x0
    80002c9a:	13e60613          	addi	a2,a2,318 # 80002dd4 <usertrap>
    80002c9e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002ca0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ca2:	8612                	mv	a2,tp
    80002ca4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca6:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002caa:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cae:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cb2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002cb6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cb8:	6f18                	ld	a4,24(a4)
    80002cba:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cbe:	6928                	ld	a0,80(a0)
    80002cc0:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002cc2:	00004717          	auipc	a4,0x4
    80002cc6:	3da70713          	addi	a4,a4,986 # 8000709c <userret>
    80002cca:	8f15                	sub	a4,a4,a3
    80002ccc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002cce:	577d                	li	a4,-1
    80002cd0:	177e                	slli	a4,a4,0x3f
    80002cd2:	8d59                	or	a0,a0,a4
    80002cd4:	9782                	jalr	a5
}
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002cde:	1101                	addi	sp,sp,-32
    80002ce0:	ec06                	sd	ra,24(sp)
    80002ce2:	e822                	sd	s0,16(sp)
    80002ce4:	e426                	sd	s1,8(sp)
    80002ce6:	e04a                	sd	s2,0(sp)
    80002ce8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cea:	00235917          	auipc	s2,0x235
    80002cee:	50e90913          	addi	s2,s2,1294 # 802381f8 <tickslock>
    80002cf2:	854a                	mv	a0,s2
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	086080e7          	jalr	134(ra) # 80000d7a <acquire>
  ticks++;
    80002cfc:	00006497          	auipc	s1,0x6
    80002d00:	c4448493          	addi	s1,s1,-956 # 80008940 <ticks>
    80002d04:	409c                	lw	a5,0(s1)
    80002d06:	2785                	addiw	a5,a5,1
    80002d08:	c09c                	sw	a5,0(s1)
  update_time();
    80002d0a:	00000097          	auipc	ra,0x0
    80002d0e:	cdc080e7          	jalr	-804(ra) # 800029e6 <update_time>
  wakeup(&ticks);
    80002d12:	8526                	mv	a0,s1
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	6a0080e7          	jalr	1696(ra) # 800023b4 <wakeup>
  release(&tickslock);
    80002d1c:	854a                	mv	a0,s2
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	110080e7          	jalr	272(ra) # 80000e2e <release>
}
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	64a2                	ld	s1,8(sp)
    80002d2c:	6902                	ld	s2,0(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	e426                	sd	s1,8(sp)
    80002d3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d3c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002d40:	00074d63          	bltz	a4,80002d5a <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002d44:	57fd                	li	a5,-1
    80002d46:	17fe                	slli	a5,a5,0x3f
    80002d48:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002d4a:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002d4c:	06f70363          	beq	a4,a5,80002db2 <devintr+0x80>
  }
}
    80002d50:	60e2                	ld	ra,24(sp)
    80002d52:	6442                	ld	s0,16(sp)
    80002d54:	64a2                	ld	s1,8(sp)
    80002d56:	6105                	addi	sp,sp,32
    80002d58:	8082                	ret
      (scause & 0xff) == 9)
    80002d5a:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002d5e:	46a5                	li	a3,9
    80002d60:	fed792e3          	bne	a5,a3,80002d44 <devintr+0x12>
    int irq = plic_claim();
    80002d64:	00004097          	auipc	ra,0x4
    80002d68:	844080e7          	jalr	-1980(ra) # 800065a8 <plic_claim>
    80002d6c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002d6e:	47a9                	li	a5,10
    80002d70:	02f50763          	beq	a0,a5,80002d9e <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002d74:	4785                	li	a5,1
    80002d76:	02f50963          	beq	a0,a5,80002da8 <devintr+0x76>
    return 1;
    80002d7a:	4505                	li	a0,1
    else if (irq)
    80002d7c:	d8f1                	beqz	s1,80002d50 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d7e:	85a6                	mv	a1,s1
    80002d80:	00005517          	auipc	a0,0x5
    80002d84:	5a050513          	addi	a0,a0,1440 # 80008320 <states.0+0x38>
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	802080e7          	jalr	-2046(ra) # 8000058a <printf>
      plic_complete(irq);
    80002d90:	8526                	mv	a0,s1
    80002d92:	00004097          	auipc	ra,0x4
    80002d96:	83a080e7          	jalr	-1990(ra) # 800065cc <plic_complete>
    return 1;
    80002d9a:	4505                	li	a0,1
    80002d9c:	bf55                	j	80002d50 <devintr+0x1e>
      uartintr();
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	bfa080e7          	jalr	-1030(ra) # 80000998 <uartintr>
    80002da6:	b7ed                	j	80002d90 <devintr+0x5e>
      virtio_disk_intr();
    80002da8:	00004097          	auipc	ra,0x4
    80002dac:	cec080e7          	jalr	-788(ra) # 80006a94 <virtio_disk_intr>
    80002db0:	b7c5                	j	80002d90 <devintr+0x5e>
    if (cpuid() == 0)
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	db4080e7          	jalr	-588(ra) # 80001b66 <cpuid>
    80002dba:	c901                	beqz	a0,80002dca <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002dbc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002dc0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002dc2:	14479073          	csrw	sip,a5
    return 2;
    80002dc6:	4509                	li	a0,2
    80002dc8:	b761                	j	80002d50 <devintr+0x1e>
      clockintr();
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	f14080e7          	jalr	-236(ra) # 80002cde <clockintr>
    80002dd2:	b7ed                	j	80002dbc <devintr+0x8a>

0000000080002dd4 <usertrap>:
{
    80002dd4:	1101                	addi	sp,sp,-32
    80002dd6:	ec06                	sd	ra,24(sp)
    80002dd8:	e822                	sd	s0,16(sp)
    80002dda:	e426                	sd	s1,8(sp)
    80002ddc:	e04a                	sd	s2,0(sp)
    80002dde:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002de0:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002de4:	1007f793          	andi	a5,a5,256
    80002de8:	efb9                	bnez	a5,80002e46 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dea:	00003797          	auipc	a5,0x3
    80002dee:	6b678793          	addi	a5,a5,1718 # 800064a0 <kernelvec>
    80002df2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	d9c080e7          	jalr	-612(ra) # 80001b92 <myproc>
    80002dfe:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e00:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e02:	14102773          	csrr	a4,sepc
    80002e06:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e08:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002e0c:	47a1                	li	a5,8
    80002e0e:	04f70463          	beq	a4,a5,80002e56 <usertrap+0x82>
    80002e12:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    80002e16:	47bd                	li	a5,15
    80002e18:	08f71663          	bne	a4,a5,80002ea4 <usertrap+0xd0>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e1c:	143027f3          	csrr	a5,stval
    if (!r_stval())
    80002e20:	e7ad                	bnez	a5,80002e8a <usertrap+0xb6>
      p->killed=1;
    80002e22:	4785                	li	a5,1
    80002e24:	d51c                	sw	a5,40(a0)
  if (killed(p))
    80002e26:	8526                	mv	a0,s1
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	7dc080e7          	jalr	2012(ra) # 80002604 <killed>
    80002e30:	e561                	bnez	a0,80002ef8 <usertrap+0x124>
  usertrapret();
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	e16080e7          	jalr	-490(ra) # 80002c48 <usertrapret>
}
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	64a2                	ld	s1,8(sp)
    80002e40:	6902                	ld	s2,0(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret
    panic("usertrap: not from user mode");
    80002e46:	00005517          	auipc	a0,0x5
    80002e4a:	4fa50513          	addi	a0,a0,1274 # 80008340 <states.0+0x58>
    80002e4e:	ffffd097          	auipc	ra,0xffffd
    80002e52:	6f2080e7          	jalr	1778(ra) # 80000540 <panic>
    if (killed(p))
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	7ae080e7          	jalr	1966(ra) # 80002604 <killed>
    80002e5e:	e105                	bnez	a0,80002e7e <usertrap+0xaa>
    p->trapframe->epc += 4;
    80002e60:	6cb8                	ld	a4,88(s1)
    80002e62:	6f1c                	ld	a5,24(a4)
    80002e64:	0791                	addi	a5,a5,4
    80002e66:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e68:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e6c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e70:	10079073          	csrw	sstatus,a5
    syscall();
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	3a0080e7          	jalr	928(ra) # 80003214 <syscall>
    80002e7c:	b76d                	j	80002e26 <usertrap+0x52>
      exit(-1);
    80002e7e:	557d                	li	a0,-1
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	604080e7          	jalr	1540(ra) # 80002484 <exit>
    80002e88:	bfe1                	j	80002e60 <usertrap+0x8c>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e8a:	14302573          	csrr	a0,stval
      if (PageFaultHandler((void *)r_stval(), p->pagetable) == -1)
    80002e8e:	68ac                	ld	a1,80(s1)
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	d06080e7          	jalr	-762(ra) # 80002b96 <PageFaultHandler>
    80002e98:	57fd                	li	a5,-1
    80002e9a:	f8f516e3          	bne	a0,a5,80002e26 <usertrap+0x52>
        p->killed = 1;
    80002e9e:	4785                	li	a5,1
    80002ea0:	d49c                	sw	a5,40(s1)
    80002ea2:	b751                	j	80002e26 <usertrap+0x52>
  else if ((which_dev = devintr()) != 0)
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	e8e080e7          	jalr	-370(ra) # 80002d32 <devintr>
    80002eac:	892a                	mv	s2,a0
    80002eae:	c901                	beqz	a0,80002ebe <usertrap+0xea>
  if (killed(p))
    80002eb0:	8526                	mv	a0,s1
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	752080e7          	jalr	1874(ra) # 80002604 <killed>
    80002eba:	c529                	beqz	a0,80002f04 <usertrap+0x130>
    80002ebc:	a83d                	j	80002efa <usertrap+0x126>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ebe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ec2:	5890                	lw	a2,48(s1)
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	49c50513          	addi	a0,a0,1180 # 80008360 <states.0+0x78>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	6be080e7          	jalr	1726(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ed4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ed8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002edc:	00005517          	auipc	a0,0x5
    80002ee0:	4b450513          	addi	a0,a0,1204 # 80008390 <states.0+0xa8>
    80002ee4:	ffffd097          	auipc	ra,0xffffd
    80002ee8:	6a6080e7          	jalr	1702(ra) # 8000058a <printf>
    setkilled(p);
    80002eec:	8526                	mv	a0,s1
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	6ea080e7          	jalr	1770(ra) # 800025d8 <setkilled>
    80002ef6:	bf05                	j	80002e26 <usertrap+0x52>
  if (killed(p))
    80002ef8:	4901                	li	s2,0
    exit(-1);
    80002efa:	557d                	li	a0,-1
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	588080e7          	jalr	1416(ra) # 80002484 <exit>
  if (which_dev == 2 && myproc()->aset == 1)
    80002f04:	4789                	li	a5,2
    80002f06:	f2f916e3          	bne	s2,a5,80002e32 <usertrap+0x5e>
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	c88080e7          	jalr	-888(ra) # 80001b92 <myproc>
    80002f12:	19052703          	lw	a4,400(a0)
    80002f16:	4785                	li	a5,1
    80002f18:	00f70763          	beq	a4,a5,80002f26 <usertrap+0x152>
    yield();
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	3f8080e7          	jalr	1016(ra) # 80002314 <yield>
    80002f24:	b739                	j	80002e32 <usertrap+0x5e>
    myproc()->atime++;
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	c6c080e7          	jalr	-916(ra) # 80001b92 <myproc>
    80002f2e:	18052783          	lw	a5,384(a0)
    80002f32:	2785                	addiw	a5,a5,1
    80002f34:	18f52023          	sw	a5,384(a0)
    if (myproc()->atime % myproc()->n == 0 && myproc()->astate == 0)
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	c5a080e7          	jalr	-934(ra) # 80001b92 <myproc>
    80002f40:	18052483          	lw	s1,384(a0)
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	c4e080e7          	jalr	-946(ra) # 80001b92 <myproc>
    80002f4c:	18853783          	ld	a5,392(a0)
    80002f50:	02f4f4b3          	remu	s1,s1,a5
    80002f54:	f4e1                	bnez	s1,80002f1c <usertrap+0x148>
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	c3c080e7          	jalr	-964(ra) # 80001b92 <myproc>
    80002f5e:	1a052783          	lw	a5,416(a0)
    80002f62:	ffcd                	bnez	a5,80002f1c <usertrap+0x148>
      *(myproc()->alarm_tp) = *(myproc()->trapframe);
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	c2e080e7          	jalr	-978(ra) # 80001b92 <myproc>
    80002f6c:	6d24                	ld	s1,88(a0)
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	c24080e7          	jalr	-988(ra) # 80001b92 <myproc>
    80002f76:	87a6                	mv	a5,s1
    80002f78:	19853703          	ld	a4,408(a0)
    80002f7c:	12048693          	addi	a3,s1,288
    80002f80:	0007b803          	ld	a6,0(a5)
    80002f84:	6788                	ld	a0,8(a5)
    80002f86:	6b8c                	ld	a1,16(a5)
    80002f88:	6f90                	ld	a2,24(a5)
    80002f8a:	01073023          	sd	a6,0(a4)
    80002f8e:	e708                	sd	a0,8(a4)
    80002f90:	eb0c                	sd	a1,16(a4)
    80002f92:	ef10                	sd	a2,24(a4)
    80002f94:	02078793          	addi	a5,a5,32
    80002f98:	02070713          	addi	a4,a4,32
    80002f9c:	fed792e3          	bne	a5,a3,80002f80 <usertrap+0x1ac>
      myproc()->astate = 1;
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	bf2080e7          	jalr	-1038(ra) # 80001b92 <myproc>
    80002fa8:	4785                	li	a5,1
    80002faa:	1af52023          	sw	a5,416(a0)
      myproc()->trapframe->epc = myproc()->alarmhandler;
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	be4080e7          	jalr	-1052(ra) # 80001b92 <myproc>
    80002fb6:	84aa                	mv	s1,a0
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	bda080e7          	jalr	-1062(ra) # 80001b92 <myproc>
    80002fc0:	6d3c                	ld	a5,88(a0)
    80002fc2:	1784b703          	ld	a4,376(s1)
    80002fc6:	ef98                	sd	a4,24(a5)
    80002fc8:	bf91                	j	80002f1c <usertrap+0x148>

0000000080002fca <kerneltrap>:
{
    80002fca:	7179                	addi	sp,sp,-48
    80002fcc:	f406                	sd	ra,40(sp)
    80002fce:	f022                	sd	s0,32(sp)
    80002fd0:	ec26                	sd	s1,24(sp)
    80002fd2:	e84a                	sd	s2,16(sp)
    80002fd4:	e44e                	sd	s3,8(sp)
    80002fd6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fd8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fdc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fe0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002fe4:	1004f793          	andi	a5,s1,256
    80002fe8:	cb85                	beqz	a5,80003018 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fee:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002ff0:	ef85                	bnez	a5,80003028 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	d40080e7          	jalr	-704(ra) # 80002d32 <devintr>
    80002ffa:	cd1d                	beqz	a0,80003038 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ffc:	4789                	li	a5,2
    80002ffe:	06f50a63          	beq	a0,a5,80003072 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003002:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003006:	10049073          	csrw	sstatus,s1
}
    8000300a:	70a2                	ld	ra,40(sp)
    8000300c:	7402                	ld	s0,32(sp)
    8000300e:	64e2                	ld	s1,24(sp)
    80003010:	6942                	ld	s2,16(sp)
    80003012:	69a2                	ld	s3,8(sp)
    80003014:	6145                	addi	sp,sp,48
    80003016:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003018:	00005517          	auipc	a0,0x5
    8000301c:	39850513          	addi	a0,a0,920 # 800083b0 <states.0+0xc8>
    80003020:	ffffd097          	auipc	ra,0xffffd
    80003024:	520080e7          	jalr	1312(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80003028:	00005517          	auipc	a0,0x5
    8000302c:	3b050513          	addi	a0,a0,944 # 800083d8 <states.0+0xf0>
    80003030:	ffffd097          	auipc	ra,0xffffd
    80003034:	510080e7          	jalr	1296(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80003038:	85ce                	mv	a1,s3
    8000303a:	00005517          	auipc	a0,0x5
    8000303e:	3be50513          	addi	a0,a0,958 # 800083f8 <states.0+0x110>
    80003042:	ffffd097          	auipc	ra,0xffffd
    80003046:	548080e7          	jalr	1352(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000304a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000304e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003052:	00005517          	auipc	a0,0x5
    80003056:	3b650513          	addi	a0,a0,950 # 80008408 <states.0+0x120>
    8000305a:	ffffd097          	auipc	ra,0xffffd
    8000305e:	530080e7          	jalr	1328(ra) # 8000058a <printf>
    panic("kerneltrap");
    80003062:	00005517          	auipc	a0,0x5
    80003066:	3be50513          	addi	a0,a0,958 # 80008420 <states.0+0x138>
    8000306a:	ffffd097          	auipc	ra,0xffffd
    8000306e:	4d6080e7          	jalr	1238(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	b20080e7          	jalr	-1248(ra) # 80001b92 <myproc>
    8000307a:	d541                	beqz	a0,80003002 <kerneltrap+0x38>
    8000307c:	fffff097          	auipc	ra,0xfffff
    80003080:	b16080e7          	jalr	-1258(ra) # 80001b92 <myproc>
    80003084:	4d18                	lw	a4,24(a0)
    80003086:	4791                	li	a5,4
    80003088:	f6f71de3          	bne	a4,a5,80003002 <kerneltrap+0x38>
    yield();
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	288080e7          	jalr	648(ra) # 80002314 <yield>
    80003094:	b7bd                	j	80003002 <kerneltrap+0x38>

0000000080003096 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	1000                	addi	s0,sp,32
    800030a0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030a2:	fffff097          	auipc	ra,0xfffff
    800030a6:	af0080e7          	jalr	-1296(ra) # 80001b92 <myproc>
  switch (n) {
    800030aa:	4795                	li	a5,5
    800030ac:	0497e163          	bltu	a5,s1,800030ee <argraw+0x58>
    800030b0:	048a                	slli	s1,s1,0x2
    800030b2:	00005717          	auipc	a4,0x5
    800030b6:	3a670713          	addi	a4,a4,934 # 80008458 <states.0+0x170>
    800030ba:	94ba                	add	s1,s1,a4
    800030bc:	409c                	lw	a5,0(s1)
    800030be:	97ba                	add	a5,a5,a4
    800030c0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030c2:	6d3c                	ld	a5,88(a0)
    800030c4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030c6:	60e2                	ld	ra,24(sp)
    800030c8:	6442                	ld	s0,16(sp)
    800030ca:	64a2                	ld	s1,8(sp)
    800030cc:	6105                	addi	sp,sp,32
    800030ce:	8082                	ret
    return p->trapframe->a1;
    800030d0:	6d3c                	ld	a5,88(a0)
    800030d2:	7fa8                	ld	a0,120(a5)
    800030d4:	bfcd                	j	800030c6 <argraw+0x30>
    return p->trapframe->a2;
    800030d6:	6d3c                	ld	a5,88(a0)
    800030d8:	63c8                	ld	a0,128(a5)
    800030da:	b7f5                	j	800030c6 <argraw+0x30>
    return p->trapframe->a3;
    800030dc:	6d3c                	ld	a5,88(a0)
    800030de:	67c8                	ld	a0,136(a5)
    800030e0:	b7dd                	j	800030c6 <argraw+0x30>
    return p->trapframe->a4;
    800030e2:	6d3c                	ld	a5,88(a0)
    800030e4:	6bc8                	ld	a0,144(a5)
    800030e6:	b7c5                	j	800030c6 <argraw+0x30>
    return p->trapframe->a5;
    800030e8:	6d3c                	ld	a5,88(a0)
    800030ea:	6fc8                	ld	a0,152(a5)
    800030ec:	bfe9                	j	800030c6 <argraw+0x30>
  panic("argraw");
    800030ee:	00005517          	auipc	a0,0x5
    800030f2:	34250513          	addi	a0,a0,834 # 80008430 <states.0+0x148>
    800030f6:	ffffd097          	auipc	ra,0xffffd
    800030fa:	44a080e7          	jalr	1098(ra) # 80000540 <panic>

00000000800030fe <fetchaddr>:
{
    800030fe:	1101                	addi	sp,sp,-32
    80003100:	ec06                	sd	ra,24(sp)
    80003102:	e822                	sd	s0,16(sp)
    80003104:	e426                	sd	s1,8(sp)
    80003106:	e04a                	sd	s2,0(sp)
    80003108:	1000                	addi	s0,sp,32
    8000310a:	84aa                	mv	s1,a0
    8000310c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000310e:	fffff097          	auipc	ra,0xfffff
    80003112:	a84080e7          	jalr	-1404(ra) # 80001b92 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003116:	653c                	ld	a5,72(a0)
    80003118:	02f4f863          	bgeu	s1,a5,80003148 <fetchaddr+0x4a>
    8000311c:	00848713          	addi	a4,s1,8
    80003120:	02e7e663          	bltu	a5,a4,8000314c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003124:	46a1                	li	a3,8
    80003126:	8626                	mv	a2,s1
    80003128:	85ca                	mv	a1,s2
    8000312a:	6928                	ld	a0,80(a0)
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	7b2080e7          	jalr	1970(ra) # 800018de <copyin>
    80003134:	00a03533          	snez	a0,a0
    80003138:	40a00533          	neg	a0,a0
}
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	64a2                	ld	s1,8(sp)
    80003142:	6902                	ld	s2,0(sp)
    80003144:	6105                	addi	sp,sp,32
    80003146:	8082                	ret
    return -1;
    80003148:	557d                	li	a0,-1
    8000314a:	bfcd                	j	8000313c <fetchaddr+0x3e>
    8000314c:	557d                	li	a0,-1
    8000314e:	b7fd                	j	8000313c <fetchaddr+0x3e>

0000000080003150 <fetchstr>:
{
    80003150:	7179                	addi	sp,sp,-48
    80003152:	f406                	sd	ra,40(sp)
    80003154:	f022                	sd	s0,32(sp)
    80003156:	ec26                	sd	s1,24(sp)
    80003158:	e84a                	sd	s2,16(sp)
    8000315a:	e44e                	sd	s3,8(sp)
    8000315c:	1800                	addi	s0,sp,48
    8000315e:	892a                	mv	s2,a0
    80003160:	84ae                	mv	s1,a1
    80003162:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	a2e080e7          	jalr	-1490(ra) # 80001b92 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    8000316c:	86ce                	mv	a3,s3
    8000316e:	864a                	mv	a2,s2
    80003170:	85a6                	mv	a1,s1
    80003172:	6928                	ld	a0,80(a0)
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	7f8080e7          	jalr	2040(ra) # 8000196c <copyinstr>
    8000317c:	00054e63          	bltz	a0,80003198 <fetchstr+0x48>
  return strlen(buf);
    80003180:	8526                	mv	a0,s1
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	e70080e7          	jalr	-400(ra) # 80000ff2 <strlen>
}
    8000318a:	70a2                	ld	ra,40(sp)
    8000318c:	7402                	ld	s0,32(sp)
    8000318e:	64e2                	ld	s1,24(sp)
    80003190:	6942                	ld	s2,16(sp)
    80003192:	69a2                	ld	s3,8(sp)
    80003194:	6145                	addi	sp,sp,48
    80003196:	8082                	ret
    return -1;
    80003198:	557d                	li	a0,-1
    8000319a:	bfc5                	j	8000318a <fetchstr+0x3a>

000000008000319c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000319c:	1101                	addi	sp,sp,-32
    8000319e:	ec06                	sd	ra,24(sp)
    800031a0:	e822                	sd	s0,16(sp)
    800031a2:	e426                	sd	s1,8(sp)
    800031a4:	1000                	addi	s0,sp,32
    800031a6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	eee080e7          	jalr	-274(ra) # 80003096 <argraw>
    800031b0:	c088                	sw	a0,0(s1)
}
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	64a2                	ld	s1,8(sp)
    800031b8:	6105                	addi	sp,sp,32
    800031ba:	8082                	ret

00000000800031bc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800031bc:	1101                	addi	sp,sp,-32
    800031be:	ec06                	sd	ra,24(sp)
    800031c0:	e822                	sd	s0,16(sp)
    800031c2:	e426                	sd	s1,8(sp)
    800031c4:	1000                	addi	s0,sp,32
    800031c6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	ece080e7          	jalr	-306(ra) # 80003096 <argraw>
    800031d0:	e088                	sd	a0,0(s1)
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031dc:	7179                	addi	sp,sp,-48
    800031de:	f406                	sd	ra,40(sp)
    800031e0:	f022                	sd	s0,32(sp)
    800031e2:	ec26                	sd	s1,24(sp)
    800031e4:	e84a                	sd	s2,16(sp)
    800031e6:	1800                	addi	s0,sp,48
    800031e8:	84ae                	mv	s1,a1
    800031ea:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031ec:	fd840593          	addi	a1,s0,-40
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	fcc080e7          	jalr	-52(ra) # 800031bc <argaddr>
  return fetchstr(addr, buf, max);
    800031f8:	864a                	mv	a2,s2
    800031fa:	85a6                	mv	a1,s1
    800031fc:	fd843503          	ld	a0,-40(s0)
    80003200:	00000097          	auipc	ra,0x0
    80003204:	f50080e7          	jalr	-176(ra) # 80003150 <fetchstr>
}
    80003208:	70a2                	ld	ra,40(sp)
    8000320a:	7402                	ld	s0,32(sp)
    8000320c:	64e2                	ld	s1,24(sp)
    8000320e:	6942                	ld	s2,16(sp)
    80003210:	6145                	addi	sp,sp,48
    80003212:	8082                	ret

0000000080003214 <syscall>:
[SYS_setpriority] sys_setpriority
};

void
syscall(void)
{
    80003214:	7179                	addi	sp,sp,-48
    80003216:	f406                	sd	ra,40(sp)
    80003218:	f022                	sd	s0,32(sp)
    8000321a:	ec26                	sd	s1,24(sp)
    8000321c:	e84a                	sd	s2,16(sp)
    8000321e:	e44e                	sd	s3,8(sp)
    80003220:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003222:	fffff097          	auipc	ra,0xfffff
    80003226:	970080e7          	jalr	-1680(ra) # 80001b92 <myproc>
    8000322a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000322c:	6d3c                	ld	a5,88(a0)
    8000322e:	0a87b903          	ld	s2,168(a5)
    80003232:	0009099b          	sext.w	s3,s2
  if(num==SYS_read)
    80003236:	4795                	li	a5,5
    80003238:	04f98863          	beq	s3,a5,80003288 <syscall+0x74>
  {
     readcount++;
  }
  if(num==SYS_getreadcount)
    8000323c:	47dd                	li	a5,23
    8000323e:	06f98b63          	beq	s3,a5,800032b4 <syscall+0xa0>
  {
    myproc()->readcount=readcount;
  }
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003242:	397d                	addiw	s2,s2,-1
    80003244:	47e5                	li	a5,25
    80003246:	0127eb63          	bltu	a5,s2,8000325c <syscall+0x48>
    8000324a:	00399713          	slli	a4,s3,0x3
    8000324e:	00005797          	auipc	a5,0x5
    80003252:	22278793          	addi	a5,a5,546 # 80008470 <syscalls>
    80003256:	97ba                	add	a5,a5,a4
    80003258:	639c                	ld	a5,0(a5)
    8000325a:	eba9                	bnez	a5,800032ac <syscall+0x98>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000325c:	86ce                	mv	a3,s3
    8000325e:	15848613          	addi	a2,s1,344
    80003262:	588c                	lw	a1,48(s1)
    80003264:	00005517          	auipc	a0,0x5
    80003268:	1d450513          	addi	a0,a0,468 # 80008438 <states.0+0x150>
    8000326c:	ffffd097          	auipc	ra,0xffffd
    80003270:	31e080e7          	jalr	798(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003274:	6cbc                	ld	a5,88(s1)
    80003276:	577d                	li	a4,-1
    80003278:	fbb8                	sd	a4,112(a5)
  }
}
    8000327a:	70a2                	ld	ra,40(sp)
    8000327c:	7402                	ld	s0,32(sp)
    8000327e:	64e2                	ld	s1,24(sp)
    80003280:	6942                	ld	s2,16(sp)
    80003282:	69a2                	ld	s3,8(sp)
    80003284:	6145                	addi	sp,sp,48
    80003286:	8082                	ret
     readcount++;
    80003288:	00005717          	auipc	a4,0x5
    8000328c:	6bc70713          	addi	a4,a4,1724 # 80008944 <readcount>
    80003290:	431c                	lw	a5,0(a4)
    80003292:	2785                	addiw	a5,a5,1
    80003294:	c31c                	sw	a5,0(a4)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003296:	397d                	addiw	s2,s2,-1
    80003298:	47e5                	li	a5,25
    8000329a:	fd27e1e3          	bltu	a5,s2,8000325c <syscall+0x48>
    8000329e:	098e                	slli	s3,s3,0x3
    800032a0:	00005797          	auipc	a5,0x5
    800032a4:	1d078793          	addi	a5,a5,464 # 80008470 <syscalls>
    800032a8:	97ce                	add	a5,a5,s3
    800032aa:	639c                	ld	a5,0(a5)
    p->trapframe->a0 = syscalls[num]();
    800032ac:	6ca4                	ld	s1,88(s1)
    800032ae:	9782                	jalr	a5
    800032b0:	f8a8                	sd	a0,112(s1)
    800032b2:	b7e1                	j	8000327a <syscall+0x66>
    myproc()->readcount=readcount;
    800032b4:	fffff097          	auipc	ra,0xfffff
    800032b8:	8de080e7          	jalr	-1826(ra) # 80001b92 <myproc>
    800032bc:	00005797          	auipc	a5,0x5
    800032c0:	6887a783          	lw	a5,1672(a5) # 80008944 <readcount>
    800032c4:	d95c                	sw	a5,52(a0)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032c6:	397d                	addiw	s2,s2,-1
    800032c8:	4765                	li	a4,25
    800032ca:	00000797          	auipc	a5,0x0
    800032ce:	22478793          	addi	a5,a5,548 # 800034ee <sys_getreadcount>
    800032d2:	fd277de3          	bgeu	a4,s2,800032ac <syscall+0x98>
    800032d6:	b759                	j	8000325c <syscall+0x48>

00000000800032d8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800032e0:	fec40593          	addi	a1,s0,-20
    800032e4:	4501                	li	a0,0
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	eb6080e7          	jalr	-330(ra) # 8000319c <argint>
  exit(n);
    800032ee:	fec42503          	lw	a0,-20(s0)
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	192080e7          	jalr	402(ra) # 80002484 <exit>
  return 0; // not reached
}
    800032fa:	4501                	li	a0,0
    800032fc:	60e2                	ld	ra,24(sp)
    800032fe:	6442                	ld	s0,16(sp)
    80003300:	6105                	addi	sp,sp,32
    80003302:	8082                	ret

0000000080003304 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003304:	1141                	addi	sp,sp,-16
    80003306:	e406                	sd	ra,8(sp)
    80003308:	e022                	sd	s0,0(sp)
    8000330a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000330c:	fffff097          	auipc	ra,0xfffff
    80003310:	886080e7          	jalr	-1914(ra) # 80001b92 <myproc>
}
    80003314:	5908                	lw	a0,48(a0)
    80003316:	60a2                	ld	ra,8(sp)
    80003318:	6402                	ld	s0,0(sp)
    8000331a:	0141                	addi	sp,sp,16
    8000331c:	8082                	ret

000000008000331e <sys_fork>:

uint64
sys_fork(void)
{
    8000331e:	1141                	addi	sp,sp,-16
    80003320:	e406                	sd	ra,8(sp)
    80003322:	e022                	sd	s0,0(sp)
    80003324:	0800                	addi	s0,sp,16
  return fork();
    80003326:	fffff097          	auipc	ra,0xfffff
    8000332a:	c98080e7          	jalr	-872(ra) # 80001fbe <fork>
}
    8000332e:	60a2                	ld	ra,8(sp)
    80003330:	6402                	ld	s0,0(sp)
    80003332:	0141                	addi	sp,sp,16
    80003334:	8082                	ret

0000000080003336 <sys_wait>:

uint64
sys_wait(void)
{
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000333e:	fe840593          	addi	a1,s0,-24
    80003342:	4501                	li	a0,0
    80003344:	00000097          	auipc	ra,0x0
    80003348:	e78080e7          	jalr	-392(ra) # 800031bc <argaddr>
  return wait(p);
    8000334c:	fe843503          	ld	a0,-24(s0)
    80003350:	fffff097          	auipc	ra,0xfffff
    80003354:	2e6080e7          	jalr	742(ra) # 80002636 <wait>
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret

0000000080003360 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003360:	7179                	addi	sp,sp,-48
    80003362:	f406                	sd	ra,40(sp)
    80003364:	f022                	sd	s0,32(sp)
    80003366:	ec26                	sd	s1,24(sp)
    80003368:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000336a:	fdc40593          	addi	a1,s0,-36
    8000336e:	4501                	li	a0,0
    80003370:	00000097          	auipc	ra,0x0
    80003374:	e2c080e7          	jalr	-468(ra) # 8000319c <argint>
  addr = myproc()->sz;
    80003378:	fffff097          	auipc	ra,0xfffff
    8000337c:	81a080e7          	jalr	-2022(ra) # 80001b92 <myproc>
    80003380:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003382:	fdc42503          	lw	a0,-36(s0)
    80003386:	fffff097          	auipc	ra,0xfffff
    8000338a:	bdc080e7          	jalr	-1060(ra) # 80001f62 <growproc>
    8000338e:	00054863          	bltz	a0,8000339e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003392:	8526                	mv	a0,s1
    80003394:	70a2                	ld	ra,40(sp)
    80003396:	7402                	ld	s0,32(sp)
    80003398:	64e2                	ld	s1,24(sp)
    8000339a:	6145                	addi	sp,sp,48
    8000339c:	8082                	ret
    return -1;
    8000339e:	54fd                	li	s1,-1
    800033a0:	bfcd                	j	80003392 <sys_sbrk+0x32>

00000000800033a2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800033a2:	7139                	addi	sp,sp,-64
    800033a4:	fc06                	sd	ra,56(sp)
    800033a6:	f822                	sd	s0,48(sp)
    800033a8:	f426                	sd	s1,40(sp)
    800033aa:	f04a                	sd	s2,32(sp)
    800033ac:	ec4e                	sd	s3,24(sp)
    800033ae:	e852                	sd	s4,16(sp)
    800033b0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800033b2:	fcc40593          	addi	a1,s0,-52
    800033b6:	4501                	li	a0,0
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	de4080e7          	jalr	-540(ra) # 8000319c <argint>
  acquire(&tickslock);
    800033c0:	00235517          	auipc	a0,0x235
    800033c4:	e3850513          	addi	a0,a0,-456 # 802381f8 <tickslock>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	9b2080e7          	jalr	-1614(ra) # 80000d7a <acquire>
  ticks0 = ticks;
    800033d0:	00005997          	auipc	s3,0x5
    800033d4:	5709a983          	lw	s3,1392(s3) # 80008940 <ticks>
  while (ticks - ticks0 < n)
    800033d8:	fcc42783          	lw	a5,-52(s0)
    800033dc:	c7b1                	beqz	a5,80003428 <sys_sleep+0x86>
  {
    myproc()->hastosleep=1;
    800033de:	4905                	li	s2,1
    {
      myproc()->hastosleep=0;
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033e0:	00235a17          	auipc	s4,0x235
    800033e4:	e18a0a13          	addi	s4,s4,-488 # 802381f8 <tickslock>
    800033e8:	00005497          	auipc	s1,0x5
    800033ec:	55848493          	addi	s1,s1,1368 # 80008940 <ticks>
    myproc()->hastosleep=1;
    800033f0:	ffffe097          	auipc	ra,0xffffe
    800033f4:	7a2080e7          	jalr	1954(ra) # 80001b92 <myproc>
    800033f8:	1b252823          	sw	s2,432(a0)
    if (killed(myproc()))
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	796080e7          	jalr	1942(ra) # 80001b92 <myproc>
    80003404:	fffff097          	auipc	ra,0xfffff
    80003408:	200080e7          	jalr	512(ra) # 80002604 <killed>
    8000340c:	e939                	bnez	a0,80003462 <sys_sleep+0xc0>
    sleep(&ticks, &tickslock);
    8000340e:	85d2                	mv	a1,s4
    80003410:	8526                	mv	a0,s1
    80003412:	fffff097          	auipc	ra,0xfffff
    80003416:	f3e080e7          	jalr	-194(ra) # 80002350 <sleep>
  while (ticks - ticks0 < n)
    8000341a:	409c                	lw	a5,0(s1)
    8000341c:	413787bb          	subw	a5,a5,s3
    80003420:	fcc42703          	lw	a4,-52(s0)
    80003424:	fce7e6e3          	bltu	a5,a4,800033f0 <sys_sleep+0x4e>
  }
  myproc()->hastosleep=0;
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	76a080e7          	jalr	1898(ra) # 80001b92 <myproc>
    80003430:	1a052823          	sw	zero,432(a0)
  myproc()->stime=0;
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	75e080e7          	jalr	1886(ra) # 80001b92 <myproc>
    8000343c:	1c052223          	sw	zero,452(a0)
  release(&tickslock);
    80003440:	00235517          	auipc	a0,0x235
    80003444:	db850513          	addi	a0,a0,-584 # 802381f8 <tickslock>
    80003448:	ffffe097          	auipc	ra,0xffffe
    8000344c:	9e6080e7          	jalr	-1562(ra) # 80000e2e <release>
  return 0;
    80003450:	4501                	li	a0,0
}
    80003452:	70e2                	ld	ra,56(sp)
    80003454:	7442                	ld	s0,48(sp)
    80003456:	74a2                	ld	s1,40(sp)
    80003458:	7902                	ld	s2,32(sp)
    8000345a:	69e2                	ld	s3,24(sp)
    8000345c:	6a42                	ld	s4,16(sp)
    8000345e:	6121                	addi	sp,sp,64
    80003460:	8082                	ret
      myproc()->hastosleep=0;
    80003462:	ffffe097          	auipc	ra,0xffffe
    80003466:	730080e7          	jalr	1840(ra) # 80001b92 <myproc>
    8000346a:	1a052823          	sw	zero,432(a0)
      release(&tickslock);
    8000346e:	00235517          	auipc	a0,0x235
    80003472:	d8a50513          	addi	a0,a0,-630 # 802381f8 <tickslock>
    80003476:	ffffe097          	auipc	ra,0xffffe
    8000347a:	9b8080e7          	jalr	-1608(ra) # 80000e2e <release>
      return -1;
    8000347e:	557d                	li	a0,-1
    80003480:	bfc9                	j	80003452 <sys_sleep+0xb0>

0000000080003482 <sys_kill>:

uint64
sys_kill(void)
{
    80003482:	1101                	addi	sp,sp,-32
    80003484:	ec06                	sd	ra,24(sp)
    80003486:	e822                	sd	s0,16(sp)
    80003488:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000348a:	fec40593          	addi	a1,s0,-20
    8000348e:	4501                	li	a0,0
    80003490:	00000097          	auipc	ra,0x0
    80003494:	d0c080e7          	jalr	-756(ra) # 8000319c <argint>
  return kill(pid);
    80003498:	fec42503          	lw	a0,-20(s0)
    8000349c:	fffff097          	auipc	ra,0xfffff
    800034a0:	0ca080e7          	jalr	202(ra) # 80002566 <kill>
}
    800034a4:	60e2                	ld	ra,24(sp)
    800034a6:	6442                	ld	s0,16(sp)
    800034a8:	6105                	addi	sp,sp,32
    800034aa:	8082                	ret

00000000800034ac <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034ac:	1101                	addi	sp,sp,-32
    800034ae:	ec06                	sd	ra,24(sp)
    800034b0:	e822                	sd	s0,16(sp)
    800034b2:	e426                	sd	s1,8(sp)
    800034b4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034b6:	00235517          	auipc	a0,0x235
    800034ba:	d4250513          	addi	a0,a0,-702 # 802381f8 <tickslock>
    800034be:	ffffe097          	auipc	ra,0xffffe
    800034c2:	8bc080e7          	jalr	-1860(ra) # 80000d7a <acquire>
  xticks = ticks;
    800034c6:	00005497          	auipc	s1,0x5
    800034ca:	47a4a483          	lw	s1,1146(s1) # 80008940 <ticks>
  release(&tickslock);
    800034ce:	00235517          	auipc	a0,0x235
    800034d2:	d2a50513          	addi	a0,a0,-726 # 802381f8 <tickslock>
    800034d6:	ffffe097          	auipc	ra,0xffffe
    800034da:	958080e7          	jalr	-1704(ra) # 80000e2e <release>
  return xticks;
}
    800034de:	02049513          	slli	a0,s1,0x20
    800034e2:	9101                	srli	a0,a0,0x20
    800034e4:	60e2                	ld	ra,24(sp)
    800034e6:	6442                	ld	s0,16(sp)
    800034e8:	64a2                	ld	s1,8(sp)
    800034ea:	6105                	addi	sp,sp,32
    800034ec:	8082                	ret

00000000800034ee <sys_getreadcount>:

// return how many times read is called
uint64
sys_getreadcount(void)
{
    800034ee:	1141                	addi	sp,sp,-16
    800034f0:	e406                	sd	ra,8(sp)
    800034f2:	e022                	sd	s0,0(sp)
    800034f4:	0800                	addi	s0,sp,16
  printf("Read count: %d\n", myproc()->readcount);
    800034f6:	ffffe097          	auipc	ra,0xffffe
    800034fa:	69c080e7          	jalr	1692(ra) # 80001b92 <myproc>
    800034fe:	594c                	lw	a1,52(a0)
    80003500:	00005517          	auipc	a0,0x5
    80003504:	04850513          	addi	a0,a0,72 # 80008548 <syscalls+0xd8>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	082080e7          	jalr	130(ra) # 8000058a <printf>
  return myproc()->readcount;
    80003510:	ffffe097          	auipc	ra,0xffffe
    80003514:	682080e7          	jalr	1666(ra) # 80001b92 <myproc>
}
    80003518:	5948                	lw	a0,52(a0)
    8000351a:	60a2                	ld	ra,8(sp)
    8000351c:	6402                	ld	s0,0(sp)
    8000351e:	0141                	addi	sp,sp,16
    80003520:	8082                	ret

0000000080003522 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80003522:	1101                	addi	sp,sp,-32
    80003524:	ec06                	sd	ra,24(sp)
    80003526:	e822                	sd	s0,16(sp)
    80003528:	1000                	addi	s0,sp,32
  uint64 n;
  argaddr(0, &n);
    8000352a:	fe840593          	addi	a1,s0,-24
    8000352e:	4501                	li	a0,0
    80003530:	00000097          	auipc	ra,0x0
    80003534:	c8c080e7          	jalr	-884(ra) # 800031bc <argaddr>
  if (n < 0)
  {
    return -1;
  }
  uint64 handler;
  argaddr(1, &handler);
    80003538:	fe040593          	addi	a1,s0,-32
    8000353c:	4505                	li	a0,1
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	c7e080e7          	jalr	-898(ra) # 800031bc <argaddr>
  if (handler < 0)
  {
    return -1;
  }
  myproc()->n = n;
    80003546:	ffffe097          	auipc	ra,0xffffe
    8000354a:	64c080e7          	jalr	1612(ra) # 80001b92 <myproc>
    8000354e:	fe843783          	ld	a5,-24(s0)
    80003552:	18f53423          	sd	a5,392(a0)
  myproc()->alarmhandler = handler;
    80003556:	ffffe097          	auipc	ra,0xffffe
    8000355a:	63c080e7          	jalr	1596(ra) # 80001b92 <myproc>
    8000355e:	fe043783          	ld	a5,-32(s0)
    80003562:	16f53c23          	sd	a5,376(a0)
  myproc()->aset=1;
    80003566:	ffffe097          	auipc	ra,0xffffe
    8000356a:	62c080e7          	jalr	1580(ra) # 80001b92 <myproc>
    8000356e:	4785                	li	a5,1
    80003570:	18f52823          	sw	a5,400(a0)
  return 0;
}
    80003574:	4501                	li	a0,0
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	6105                	addi	sp,sp,32
    8000357c:	8082                	ret

000000008000357e <sys_setpriority>:

uint64 sys_setpriority(void)
{
    8000357e:	7179                	addi	sp,sp,-48
    80003580:	f406                	sd	ra,40(sp)
    80003582:	f022                	sd	s0,32(sp)
    80003584:	ec26                	sd	s1,24(sp)
    80003586:	e84a                	sd	s2,16(sp)
    80003588:	1800                	addi	s0,sp,48
  int pid,new_priority;
  argint(0,&pid);
    8000358a:	fdc40593          	addi	a1,s0,-36
    8000358e:	4501                	li	a0,0
    80003590:	00000097          	auipc	ra,0x0
    80003594:	c0c080e7          	jalr	-1012(ra) # 8000319c <argint>
  argint(1,&new_priority);
    80003598:	fd840593          	addi	a1,s0,-40
    8000359c:	4505                	li	a0,1
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	bfe080e7          	jalr	-1026(ra) # 8000319c <argint>
  struct proc* p;
  for(p=proc;p<&proc[NPROC];p++)
    800035a6:	0022e497          	auipc	s1,0x22e
    800035aa:	a5248493          	addi	s1,s1,-1454 # 80230ff8 <proc>
    800035ae:	00235917          	auipc	s2,0x235
    800035b2:	c4a90913          	addi	s2,s2,-950 # 802381f8 <tickslock>
  {
    acquire(&p->lock);
    800035b6:	8526                	mv	a0,s1
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	7c2080e7          	jalr	1986(ra) # 80000d7a <acquire>
    if(p->pid==pid)
    800035c0:	5898                	lw	a4,48(s1)
    800035c2:	fdc42783          	lw	a5,-36(s0)
    800035c6:	00f70c63          	beq	a4,a5,800035de <sys_setpriority+0x60>
      p->rbi=25;
      p->dp=p->priority+p->rbi;
      release(&p->lock);
      break;
    }
    release(&p->lock);
    800035ca:	8526                	mv	a0,s1
    800035cc:	ffffe097          	auipc	ra,0xffffe
    800035d0:	862080e7          	jalr	-1950(ra) # 80000e2e <release>
  for(p=proc;p<&proc[NPROC];p++)
    800035d4:	1c848493          	addi	s1,s1,456
    800035d8:	fd249fe3          	bne	s1,s2,800035b6 <sys_setpriority+0x38>
    800035dc:	a005                	j	800035fc <sys_setpriority+0x7e>
      p->priority=new_priority;
    800035de:	fd842783          	lw	a5,-40(s0)
    800035e2:	1af4a223          	sw	a5,420(s1)
      p->rbi=25;
    800035e6:	4765                	li	a4,25
    800035e8:	1ae4aa23          	sw	a4,436(s1)
      p->dp=p->priority+p->rbi;
    800035ec:	27e5                	addiw	a5,a5,25
    800035ee:	1af4ac23          	sw	a5,440(s1)
      release(&p->lock);
    800035f2:	8526                	mv	a0,s1
    800035f4:	ffffe097          	auipc	ra,0xffffe
    800035f8:	83a080e7          	jalr	-1990(ra) # 80000e2e <release>
  }
  return 0;
}
    800035fc:	4501                	li	a0,0
    800035fe:	70a2                	ld	ra,40(sp)
    80003600:	7402                	ld	s0,32(sp)
    80003602:	64e2                	ld	s1,24(sp)
    80003604:	6942                	ld	s2,16(sp)
    80003606:	6145                	addi	sp,sp,48
    80003608:	8082                	ret

000000008000360a <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    8000360a:	1101                	addi	sp,sp,-32
    8000360c:	ec06                	sd	ra,24(sp)
    8000360e:	e822                	sd	s0,16(sp)
    80003610:	e426                	sd	s1,8(sp)
    80003612:	1000                	addi	s0,sp,32
   *(myproc()->trapframe)=*(myproc()->alarm_tp);
    80003614:	ffffe097          	auipc	ra,0xffffe
    80003618:	57e080e7          	jalr	1406(ra) # 80001b92 <myproc>
    8000361c:	19853483          	ld	s1,408(a0)
    80003620:	ffffe097          	auipc	ra,0xffffe
    80003624:	572080e7          	jalr	1394(ra) # 80001b92 <myproc>
    80003628:	87a6                	mv	a5,s1
    8000362a:	6d38                	ld	a4,88(a0)
    8000362c:	12048493          	addi	s1,s1,288
    80003630:	6388                	ld	a0,0(a5)
    80003632:	678c                	ld	a1,8(a5)
    80003634:	6b90                	ld	a2,16(a5)
    80003636:	6f94                	ld	a3,24(a5)
    80003638:	e308                	sd	a0,0(a4)
    8000363a:	e70c                	sd	a1,8(a4)
    8000363c:	eb10                	sd	a2,16(a4)
    8000363e:	ef14                	sd	a3,24(a4)
    80003640:	02078793          	addi	a5,a5,32
    80003644:	02070713          	addi	a4,a4,32
    80003648:	fe9794e3          	bne	a5,s1,80003630 <sys_sigreturn+0x26>
   myproc()->astate=0;
    8000364c:	ffffe097          	auipc	ra,0xffffe
    80003650:	546080e7          	jalr	1350(ra) # 80001b92 <myproc>
    80003654:	1a052023          	sw	zero,416(a0)
   myproc()->atime=0;
    80003658:	ffffe097          	auipc	ra,0xffffe
    8000365c:	53a080e7          	jalr	1338(ra) # 80001b92 <myproc>
    80003660:	18052023          	sw	zero,384(a0)
   usertrapret();
    80003664:	fffff097          	auipc	ra,0xfffff
    80003668:	5e4080e7          	jalr	1508(ra) # 80002c48 <usertrapret>
   return 0;
}
    8000366c:	4501                	li	a0,0
    8000366e:	60e2                	ld	ra,24(sp)
    80003670:	6442                	ld	s0,16(sp)
    80003672:	64a2                	ld	s1,8(sp)
    80003674:	6105                	addi	sp,sp,32
    80003676:	8082                	ret

0000000080003678 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003678:	7139                	addi	sp,sp,-64
    8000367a:	fc06                	sd	ra,56(sp)
    8000367c:	f822                	sd	s0,48(sp)
    8000367e:	f426                	sd	s1,40(sp)
    80003680:	f04a                	sd	s2,32(sp)
    80003682:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003684:	fd840593          	addi	a1,s0,-40
    80003688:	4501                	li	a0,0
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	b32080e7          	jalr	-1230(ra) # 800031bc <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003692:	fd040593          	addi	a1,s0,-48
    80003696:	4505                	li	a0,1
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	b24080e7          	jalr	-1244(ra) # 800031bc <argaddr>
  argaddr(2, &addr2);
    800036a0:	fc840593          	addi	a1,s0,-56
    800036a4:	4509                	li	a0,2
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	b16080e7          	jalr	-1258(ra) # 800031bc <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800036ae:	fc040613          	addi	a2,s0,-64
    800036b2:	fc440593          	addi	a1,s0,-60
    800036b6:	fd843503          	ld	a0,-40(s0)
    800036ba:	fffff097          	auipc	ra,0xfffff
    800036be:	1e0080e7          	jalr	480(ra) # 8000289a <waitx>
    800036c2:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800036c4:	ffffe097          	auipc	ra,0xffffe
    800036c8:	4ce080e7          	jalr	1230(ra) # 80001b92 <myproc>
    800036cc:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036ce:	4691                	li	a3,4
    800036d0:	fc440613          	addi	a2,s0,-60
    800036d4:	fd043583          	ld	a1,-48(s0)
    800036d8:	6928                	ld	a0,80(a0)
    800036da:	ffffe097          	auipc	ra,0xffffe
    800036de:	140080e7          	jalr	320(ra) # 8000181a <copyout>
    return -1;
    800036e2:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036e4:	00054f63          	bltz	a0,80003702 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800036e8:	4691                	li	a3,4
    800036ea:	fc040613          	addi	a2,s0,-64
    800036ee:	fc843583          	ld	a1,-56(s0)
    800036f2:	68a8                	ld	a0,80(s1)
    800036f4:	ffffe097          	auipc	ra,0xffffe
    800036f8:	126080e7          	jalr	294(ra) # 8000181a <copyout>
    800036fc:	00054a63          	bltz	a0,80003710 <sys_waitx+0x98>
    return -1;
  return ret;
    80003700:	87ca                	mv	a5,s2
    80003702:	853e                	mv	a0,a5
    80003704:	70e2                	ld	ra,56(sp)
    80003706:	7442                	ld	s0,48(sp)
    80003708:	74a2                	ld	s1,40(sp)
    8000370a:	7902                	ld	s2,32(sp)
    8000370c:	6121                	addi	sp,sp,64
    8000370e:	8082                	ret
    return -1;
    80003710:	57fd                	li	a5,-1
    80003712:	bfc5                	j	80003702 <sys_waitx+0x8a>

0000000080003714 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003714:	7179                	addi	sp,sp,-48
    80003716:	f406                	sd	ra,40(sp)
    80003718:	f022                	sd	s0,32(sp)
    8000371a:	ec26                	sd	s1,24(sp)
    8000371c:	e84a                	sd	s2,16(sp)
    8000371e:	e44e                	sd	s3,8(sp)
    80003720:	e052                	sd	s4,0(sp)
    80003722:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003724:	00005597          	auipc	a1,0x5
    80003728:	e3458593          	addi	a1,a1,-460 # 80008558 <syscalls+0xe8>
    8000372c:	00235517          	auipc	a0,0x235
    80003730:	ae450513          	addi	a0,a0,-1308 # 80238210 <bcache>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	5b6080e7          	jalr	1462(ra) # 80000cea <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000373c:	0023d797          	auipc	a5,0x23d
    80003740:	ad478793          	addi	a5,a5,-1324 # 80240210 <bcache+0x8000>
    80003744:	0023d717          	auipc	a4,0x23d
    80003748:	d3470713          	addi	a4,a4,-716 # 80240478 <bcache+0x8268>
    8000374c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003750:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003754:	00235497          	auipc	s1,0x235
    80003758:	ad448493          	addi	s1,s1,-1324 # 80238228 <bcache+0x18>
    b->next = bcache.head.next;
    8000375c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000375e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003760:	00005a17          	auipc	s4,0x5
    80003764:	e00a0a13          	addi	s4,s4,-512 # 80008560 <syscalls+0xf0>
    b->next = bcache.head.next;
    80003768:	2b893783          	ld	a5,696(s2)
    8000376c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000376e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003772:	85d2                	mv	a1,s4
    80003774:	01048513          	addi	a0,s1,16
    80003778:	00001097          	auipc	ra,0x1
    8000377c:	4c8080e7          	jalr	1224(ra) # 80004c40 <initsleeplock>
    bcache.head.next->prev = b;
    80003780:	2b893783          	ld	a5,696(s2)
    80003784:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003786:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000378a:	45848493          	addi	s1,s1,1112
    8000378e:	fd349de3          	bne	s1,s3,80003768 <binit+0x54>
  }
}
    80003792:	70a2                	ld	ra,40(sp)
    80003794:	7402                	ld	s0,32(sp)
    80003796:	64e2                	ld	s1,24(sp)
    80003798:	6942                	ld	s2,16(sp)
    8000379a:	69a2                	ld	s3,8(sp)
    8000379c:	6a02                	ld	s4,0(sp)
    8000379e:	6145                	addi	sp,sp,48
    800037a0:	8082                	ret

00000000800037a2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800037a2:	7179                	addi	sp,sp,-48
    800037a4:	f406                	sd	ra,40(sp)
    800037a6:	f022                	sd	s0,32(sp)
    800037a8:	ec26                	sd	s1,24(sp)
    800037aa:	e84a                	sd	s2,16(sp)
    800037ac:	e44e                	sd	s3,8(sp)
    800037ae:	1800                	addi	s0,sp,48
    800037b0:	892a                	mv	s2,a0
    800037b2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800037b4:	00235517          	auipc	a0,0x235
    800037b8:	a5c50513          	addi	a0,a0,-1444 # 80238210 <bcache>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	5be080e7          	jalr	1470(ra) # 80000d7a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037c4:	0023d497          	auipc	s1,0x23d
    800037c8:	d044b483          	ld	s1,-764(s1) # 802404c8 <bcache+0x82b8>
    800037cc:	0023d797          	auipc	a5,0x23d
    800037d0:	cac78793          	addi	a5,a5,-852 # 80240478 <bcache+0x8268>
    800037d4:	02f48f63          	beq	s1,a5,80003812 <bread+0x70>
    800037d8:	873e                	mv	a4,a5
    800037da:	a021                	j	800037e2 <bread+0x40>
    800037dc:	68a4                	ld	s1,80(s1)
    800037de:	02e48a63          	beq	s1,a4,80003812 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800037e2:	449c                	lw	a5,8(s1)
    800037e4:	ff279ce3          	bne	a5,s2,800037dc <bread+0x3a>
    800037e8:	44dc                	lw	a5,12(s1)
    800037ea:	ff3799e3          	bne	a5,s3,800037dc <bread+0x3a>
      b->refcnt++;
    800037ee:	40bc                	lw	a5,64(s1)
    800037f0:	2785                	addiw	a5,a5,1
    800037f2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037f4:	00235517          	auipc	a0,0x235
    800037f8:	a1c50513          	addi	a0,a0,-1508 # 80238210 <bcache>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	632080e7          	jalr	1586(ra) # 80000e2e <release>
      acquiresleep(&b->lock);
    80003804:	01048513          	addi	a0,s1,16
    80003808:	00001097          	auipc	ra,0x1
    8000380c:	472080e7          	jalr	1138(ra) # 80004c7a <acquiresleep>
      return b;
    80003810:	a8b9                	j	8000386e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003812:	0023d497          	auipc	s1,0x23d
    80003816:	cae4b483          	ld	s1,-850(s1) # 802404c0 <bcache+0x82b0>
    8000381a:	0023d797          	auipc	a5,0x23d
    8000381e:	c5e78793          	addi	a5,a5,-930 # 80240478 <bcache+0x8268>
    80003822:	00f48863          	beq	s1,a5,80003832 <bread+0x90>
    80003826:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003828:	40bc                	lw	a5,64(s1)
    8000382a:	cf81                	beqz	a5,80003842 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000382c:	64a4                	ld	s1,72(s1)
    8000382e:	fee49de3          	bne	s1,a4,80003828 <bread+0x86>
  panic("bget: no buffers");
    80003832:	00005517          	auipc	a0,0x5
    80003836:	d3650513          	addi	a0,a0,-714 # 80008568 <syscalls+0xf8>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	d06080e7          	jalr	-762(ra) # 80000540 <panic>
      b->dev = dev;
    80003842:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003846:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000384a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000384e:	4785                	li	a5,1
    80003850:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003852:	00235517          	auipc	a0,0x235
    80003856:	9be50513          	addi	a0,a0,-1602 # 80238210 <bcache>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	5d4080e7          	jalr	1492(ra) # 80000e2e <release>
      acquiresleep(&b->lock);
    80003862:	01048513          	addi	a0,s1,16
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	414080e7          	jalr	1044(ra) # 80004c7a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000386e:	409c                	lw	a5,0(s1)
    80003870:	cb89                	beqz	a5,80003882 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003872:	8526                	mv	a0,s1
    80003874:	70a2                	ld	ra,40(sp)
    80003876:	7402                	ld	s0,32(sp)
    80003878:	64e2                	ld	s1,24(sp)
    8000387a:	6942                	ld	s2,16(sp)
    8000387c:	69a2                	ld	s3,8(sp)
    8000387e:	6145                	addi	sp,sp,48
    80003880:	8082                	ret
    virtio_disk_rw(b, 0);
    80003882:	4581                	li	a1,0
    80003884:	8526                	mv	a0,s1
    80003886:	00003097          	auipc	ra,0x3
    8000388a:	fdc080e7          	jalr	-36(ra) # 80006862 <virtio_disk_rw>
    b->valid = 1;
    8000388e:	4785                	li	a5,1
    80003890:	c09c                	sw	a5,0(s1)
  return b;
    80003892:	b7c5                	j	80003872 <bread+0xd0>

0000000080003894 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003894:	1101                	addi	sp,sp,-32
    80003896:	ec06                	sd	ra,24(sp)
    80003898:	e822                	sd	s0,16(sp)
    8000389a:	e426                	sd	s1,8(sp)
    8000389c:	1000                	addi	s0,sp,32
    8000389e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038a0:	0541                	addi	a0,a0,16
    800038a2:	00001097          	auipc	ra,0x1
    800038a6:	472080e7          	jalr	1138(ra) # 80004d14 <holdingsleep>
    800038aa:	cd01                	beqz	a0,800038c2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800038ac:	4585                	li	a1,1
    800038ae:	8526                	mv	a0,s1
    800038b0:	00003097          	auipc	ra,0x3
    800038b4:	fb2080e7          	jalr	-78(ra) # 80006862 <virtio_disk_rw>
}
    800038b8:	60e2                	ld	ra,24(sp)
    800038ba:	6442                	ld	s0,16(sp)
    800038bc:	64a2                	ld	s1,8(sp)
    800038be:	6105                	addi	sp,sp,32
    800038c0:	8082                	ret
    panic("bwrite");
    800038c2:	00005517          	auipc	a0,0x5
    800038c6:	cbe50513          	addi	a0,a0,-834 # 80008580 <syscalls+0x110>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	c76080e7          	jalr	-906(ra) # 80000540 <panic>

00000000800038d2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038d2:	1101                	addi	sp,sp,-32
    800038d4:	ec06                	sd	ra,24(sp)
    800038d6:	e822                	sd	s0,16(sp)
    800038d8:	e426                	sd	s1,8(sp)
    800038da:	e04a                	sd	s2,0(sp)
    800038dc:	1000                	addi	s0,sp,32
    800038de:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038e0:	01050913          	addi	s2,a0,16
    800038e4:	854a                	mv	a0,s2
    800038e6:	00001097          	auipc	ra,0x1
    800038ea:	42e080e7          	jalr	1070(ra) # 80004d14 <holdingsleep>
    800038ee:	c92d                	beqz	a0,80003960 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800038f0:	854a                	mv	a0,s2
    800038f2:	00001097          	auipc	ra,0x1
    800038f6:	3de080e7          	jalr	990(ra) # 80004cd0 <releasesleep>

  acquire(&bcache.lock);
    800038fa:	00235517          	auipc	a0,0x235
    800038fe:	91650513          	addi	a0,a0,-1770 # 80238210 <bcache>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	478080e7          	jalr	1144(ra) # 80000d7a <acquire>
  b->refcnt--;
    8000390a:	40bc                	lw	a5,64(s1)
    8000390c:	37fd                	addiw	a5,a5,-1
    8000390e:	0007871b          	sext.w	a4,a5
    80003912:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003914:	eb05                	bnez	a4,80003944 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003916:	68bc                	ld	a5,80(s1)
    80003918:	64b8                	ld	a4,72(s1)
    8000391a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000391c:	64bc                	ld	a5,72(s1)
    8000391e:	68b8                	ld	a4,80(s1)
    80003920:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003922:	0023d797          	auipc	a5,0x23d
    80003926:	8ee78793          	addi	a5,a5,-1810 # 80240210 <bcache+0x8000>
    8000392a:	2b87b703          	ld	a4,696(a5)
    8000392e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003930:	0023d717          	auipc	a4,0x23d
    80003934:	b4870713          	addi	a4,a4,-1208 # 80240478 <bcache+0x8268>
    80003938:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000393a:	2b87b703          	ld	a4,696(a5)
    8000393e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003940:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003944:	00235517          	auipc	a0,0x235
    80003948:	8cc50513          	addi	a0,a0,-1844 # 80238210 <bcache>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	4e2080e7          	jalr	1250(ra) # 80000e2e <release>
}
    80003954:	60e2                	ld	ra,24(sp)
    80003956:	6442                	ld	s0,16(sp)
    80003958:	64a2                	ld	s1,8(sp)
    8000395a:	6902                	ld	s2,0(sp)
    8000395c:	6105                	addi	sp,sp,32
    8000395e:	8082                	ret
    panic("brelse");
    80003960:	00005517          	auipc	a0,0x5
    80003964:	c2850513          	addi	a0,a0,-984 # 80008588 <syscalls+0x118>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	bd8080e7          	jalr	-1064(ra) # 80000540 <panic>

0000000080003970 <bpin>:

void
bpin(struct buf *b) {
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000397c:	00235517          	auipc	a0,0x235
    80003980:	89450513          	addi	a0,a0,-1900 # 80238210 <bcache>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	3f6080e7          	jalr	1014(ra) # 80000d7a <acquire>
  b->refcnt++;
    8000398c:	40bc                	lw	a5,64(s1)
    8000398e:	2785                	addiw	a5,a5,1
    80003990:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003992:	00235517          	auipc	a0,0x235
    80003996:	87e50513          	addi	a0,a0,-1922 # 80238210 <bcache>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	494080e7          	jalr	1172(ra) # 80000e2e <release>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6105                	addi	sp,sp,32
    800039aa:	8082                	ret

00000000800039ac <bunpin>:

void
bunpin(struct buf *b) {
    800039ac:	1101                	addi	sp,sp,-32
    800039ae:	ec06                	sd	ra,24(sp)
    800039b0:	e822                	sd	s0,16(sp)
    800039b2:	e426                	sd	s1,8(sp)
    800039b4:	1000                	addi	s0,sp,32
    800039b6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039b8:	00235517          	auipc	a0,0x235
    800039bc:	85850513          	addi	a0,a0,-1960 # 80238210 <bcache>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	3ba080e7          	jalr	954(ra) # 80000d7a <acquire>
  b->refcnt--;
    800039c8:	40bc                	lw	a5,64(s1)
    800039ca:	37fd                	addiw	a5,a5,-1
    800039cc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039ce:	00235517          	auipc	a0,0x235
    800039d2:	84250513          	addi	a0,a0,-1982 # 80238210 <bcache>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	458080e7          	jalr	1112(ra) # 80000e2e <release>
}
    800039de:	60e2                	ld	ra,24(sp)
    800039e0:	6442                	ld	s0,16(sp)
    800039e2:	64a2                	ld	s1,8(sp)
    800039e4:	6105                	addi	sp,sp,32
    800039e6:	8082                	ret

00000000800039e8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800039e8:	1101                	addi	sp,sp,-32
    800039ea:	ec06                	sd	ra,24(sp)
    800039ec:	e822                	sd	s0,16(sp)
    800039ee:	e426                	sd	s1,8(sp)
    800039f0:	e04a                	sd	s2,0(sp)
    800039f2:	1000                	addi	s0,sp,32
    800039f4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800039f6:	00d5d59b          	srliw	a1,a1,0xd
    800039fa:	0023d797          	auipc	a5,0x23d
    800039fe:	ef27a783          	lw	a5,-270(a5) # 802408ec <sb+0x1c>
    80003a02:	9dbd                	addw	a1,a1,a5
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	d9e080e7          	jalr	-610(ra) # 800037a2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a0c:	0074f713          	andi	a4,s1,7
    80003a10:	4785                	li	a5,1
    80003a12:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a16:	14ce                	slli	s1,s1,0x33
    80003a18:	90d9                	srli	s1,s1,0x36
    80003a1a:	00950733          	add	a4,a0,s1
    80003a1e:	05874703          	lbu	a4,88(a4)
    80003a22:	00e7f6b3          	and	a3,a5,a4
    80003a26:	c69d                	beqz	a3,80003a54 <bfree+0x6c>
    80003a28:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a2a:	94aa                	add	s1,s1,a0
    80003a2c:	fff7c793          	not	a5,a5
    80003a30:	8f7d                	and	a4,a4,a5
    80003a32:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003a36:	00001097          	auipc	ra,0x1
    80003a3a:	126080e7          	jalr	294(ra) # 80004b5c <log_write>
  brelse(bp);
    80003a3e:	854a                	mv	a0,s2
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	e92080e7          	jalr	-366(ra) # 800038d2 <brelse>
}
    80003a48:	60e2                	ld	ra,24(sp)
    80003a4a:	6442                	ld	s0,16(sp)
    80003a4c:	64a2                	ld	s1,8(sp)
    80003a4e:	6902                	ld	s2,0(sp)
    80003a50:	6105                	addi	sp,sp,32
    80003a52:	8082                	ret
    panic("freeing free block");
    80003a54:	00005517          	auipc	a0,0x5
    80003a58:	b3c50513          	addi	a0,a0,-1220 # 80008590 <syscalls+0x120>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	ae4080e7          	jalr	-1308(ra) # 80000540 <panic>

0000000080003a64 <balloc>:
{
    80003a64:	711d                	addi	sp,sp,-96
    80003a66:	ec86                	sd	ra,88(sp)
    80003a68:	e8a2                	sd	s0,80(sp)
    80003a6a:	e4a6                	sd	s1,72(sp)
    80003a6c:	e0ca                	sd	s2,64(sp)
    80003a6e:	fc4e                	sd	s3,56(sp)
    80003a70:	f852                	sd	s4,48(sp)
    80003a72:	f456                	sd	s5,40(sp)
    80003a74:	f05a                	sd	s6,32(sp)
    80003a76:	ec5e                	sd	s7,24(sp)
    80003a78:	e862                	sd	s8,16(sp)
    80003a7a:	e466                	sd	s9,8(sp)
    80003a7c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a7e:	0023d797          	auipc	a5,0x23d
    80003a82:	e567a783          	lw	a5,-426(a5) # 802408d4 <sb+0x4>
    80003a86:	cff5                	beqz	a5,80003b82 <balloc+0x11e>
    80003a88:	8baa                	mv	s7,a0
    80003a8a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a8c:	0023db17          	auipc	s6,0x23d
    80003a90:	e44b0b13          	addi	s6,s6,-444 # 802408d0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a94:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a96:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a98:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a9a:	6c89                	lui	s9,0x2
    80003a9c:	a061                	j	80003b24 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a9e:	97ca                	add	a5,a5,s2
    80003aa0:	8e55                	or	a2,a2,a3
    80003aa2:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	00001097          	auipc	ra,0x1
    80003aac:	0b4080e7          	jalr	180(ra) # 80004b5c <log_write>
        brelse(bp);
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	e20080e7          	jalr	-480(ra) # 800038d2 <brelse>
  bp = bread(dev, bno);
    80003aba:	85a6                	mv	a1,s1
    80003abc:	855e                	mv	a0,s7
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	ce4080e7          	jalr	-796(ra) # 800037a2 <bread>
    80003ac6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003ac8:	40000613          	li	a2,1024
    80003acc:	4581                	li	a1,0
    80003ace:	05850513          	addi	a0,a0,88
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	3a4080e7          	jalr	932(ra) # 80000e76 <memset>
  log_write(bp);
    80003ada:	854a                	mv	a0,s2
    80003adc:	00001097          	auipc	ra,0x1
    80003ae0:	080080e7          	jalr	128(ra) # 80004b5c <log_write>
  brelse(bp);
    80003ae4:	854a                	mv	a0,s2
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	dec080e7          	jalr	-532(ra) # 800038d2 <brelse>
}
    80003aee:	8526                	mv	a0,s1
    80003af0:	60e6                	ld	ra,88(sp)
    80003af2:	6446                	ld	s0,80(sp)
    80003af4:	64a6                	ld	s1,72(sp)
    80003af6:	6906                	ld	s2,64(sp)
    80003af8:	79e2                	ld	s3,56(sp)
    80003afa:	7a42                	ld	s4,48(sp)
    80003afc:	7aa2                	ld	s5,40(sp)
    80003afe:	7b02                	ld	s6,32(sp)
    80003b00:	6be2                	ld	s7,24(sp)
    80003b02:	6c42                	ld	s8,16(sp)
    80003b04:	6ca2                	ld	s9,8(sp)
    80003b06:	6125                	addi	sp,sp,96
    80003b08:	8082                	ret
    brelse(bp);
    80003b0a:	854a                	mv	a0,s2
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	dc6080e7          	jalr	-570(ra) # 800038d2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003b14:	015c87bb          	addw	a5,s9,s5
    80003b18:	00078a9b          	sext.w	s5,a5
    80003b1c:	004b2703          	lw	a4,4(s6)
    80003b20:	06eaf163          	bgeu	s5,a4,80003b82 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003b24:	41fad79b          	sraiw	a5,s5,0x1f
    80003b28:	0137d79b          	srliw	a5,a5,0x13
    80003b2c:	015787bb          	addw	a5,a5,s5
    80003b30:	40d7d79b          	sraiw	a5,a5,0xd
    80003b34:	01cb2583          	lw	a1,28(s6)
    80003b38:	9dbd                	addw	a1,a1,a5
    80003b3a:	855e                	mv	a0,s7
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	c66080e7          	jalr	-922(ra) # 800037a2 <bread>
    80003b44:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b46:	004b2503          	lw	a0,4(s6)
    80003b4a:	000a849b          	sext.w	s1,s5
    80003b4e:	8762                	mv	a4,s8
    80003b50:	faa4fde3          	bgeu	s1,a0,80003b0a <balloc+0xa6>
      m = 1 << (bi % 8);
    80003b54:	00777693          	andi	a3,a4,7
    80003b58:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b5c:	41f7579b          	sraiw	a5,a4,0x1f
    80003b60:	01d7d79b          	srliw	a5,a5,0x1d
    80003b64:	9fb9                	addw	a5,a5,a4
    80003b66:	4037d79b          	sraiw	a5,a5,0x3
    80003b6a:	00f90633          	add	a2,s2,a5
    80003b6e:	05864603          	lbu	a2,88(a2)
    80003b72:	00c6f5b3          	and	a1,a3,a2
    80003b76:	d585                	beqz	a1,80003a9e <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b78:	2705                	addiw	a4,a4,1
    80003b7a:	2485                	addiw	s1,s1,1
    80003b7c:	fd471ae3          	bne	a4,s4,80003b50 <balloc+0xec>
    80003b80:	b769                	j	80003b0a <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003b82:	00005517          	auipc	a0,0x5
    80003b86:	a2650513          	addi	a0,a0,-1498 # 800085a8 <syscalls+0x138>
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	a00080e7          	jalr	-1536(ra) # 8000058a <printf>
  return 0;
    80003b92:	4481                	li	s1,0
    80003b94:	bfa9                	j	80003aee <balloc+0x8a>

0000000080003b96 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b96:	7179                	addi	sp,sp,-48
    80003b98:	f406                	sd	ra,40(sp)
    80003b9a:	f022                	sd	s0,32(sp)
    80003b9c:	ec26                	sd	s1,24(sp)
    80003b9e:	e84a                	sd	s2,16(sp)
    80003ba0:	e44e                	sd	s3,8(sp)
    80003ba2:	e052                	sd	s4,0(sp)
    80003ba4:	1800                	addi	s0,sp,48
    80003ba6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ba8:	47ad                	li	a5,11
    80003baa:	02b7e863          	bltu	a5,a1,80003bda <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003bae:	02059793          	slli	a5,a1,0x20
    80003bb2:	01e7d593          	srli	a1,a5,0x1e
    80003bb6:	00b504b3          	add	s1,a0,a1
    80003bba:	0504a903          	lw	s2,80(s1)
    80003bbe:	06091e63          	bnez	s2,80003c3a <bmap+0xa4>
      addr = balloc(ip->dev);
    80003bc2:	4108                	lw	a0,0(a0)
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	ea0080e7          	jalr	-352(ra) # 80003a64 <balloc>
    80003bcc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003bd0:	06090563          	beqz	s2,80003c3a <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003bd4:	0524a823          	sw	s2,80(s1)
    80003bd8:	a08d                	j	80003c3a <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003bda:	ff45849b          	addiw	s1,a1,-12
    80003bde:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003be2:	0ff00793          	li	a5,255
    80003be6:	08e7e563          	bltu	a5,a4,80003c70 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003bea:	08052903          	lw	s2,128(a0)
    80003bee:	00091d63          	bnez	s2,80003c08 <bmap+0x72>
      addr = balloc(ip->dev);
    80003bf2:	4108                	lw	a0,0(a0)
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	e70080e7          	jalr	-400(ra) # 80003a64 <balloc>
    80003bfc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003c00:	02090d63          	beqz	s2,80003c3a <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003c04:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003c08:	85ca                	mv	a1,s2
    80003c0a:	0009a503          	lw	a0,0(s3)
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	b94080e7          	jalr	-1132(ra) # 800037a2 <bread>
    80003c16:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003c18:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003c1c:	02049713          	slli	a4,s1,0x20
    80003c20:	01e75593          	srli	a1,a4,0x1e
    80003c24:	00b784b3          	add	s1,a5,a1
    80003c28:	0004a903          	lw	s2,0(s1)
    80003c2c:	02090063          	beqz	s2,80003c4c <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003c30:	8552                	mv	a0,s4
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	ca0080e7          	jalr	-864(ra) # 800038d2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	70a2                	ld	ra,40(sp)
    80003c3e:	7402                	ld	s0,32(sp)
    80003c40:	64e2                	ld	s1,24(sp)
    80003c42:	6942                	ld	s2,16(sp)
    80003c44:	69a2                	ld	s3,8(sp)
    80003c46:	6a02                	ld	s4,0(sp)
    80003c48:	6145                	addi	sp,sp,48
    80003c4a:	8082                	ret
      addr = balloc(ip->dev);
    80003c4c:	0009a503          	lw	a0,0(s3)
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	e14080e7          	jalr	-492(ra) # 80003a64 <balloc>
    80003c58:	0005091b          	sext.w	s2,a0
      if(addr){
    80003c5c:	fc090ae3          	beqz	s2,80003c30 <bmap+0x9a>
        a[bn] = addr;
    80003c60:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003c64:	8552                	mv	a0,s4
    80003c66:	00001097          	auipc	ra,0x1
    80003c6a:	ef6080e7          	jalr	-266(ra) # 80004b5c <log_write>
    80003c6e:	b7c9                	j	80003c30 <bmap+0x9a>
  panic("bmap: out of range");
    80003c70:	00005517          	auipc	a0,0x5
    80003c74:	95050513          	addi	a0,a0,-1712 # 800085c0 <syscalls+0x150>
    80003c78:	ffffd097          	auipc	ra,0xffffd
    80003c7c:	8c8080e7          	jalr	-1848(ra) # 80000540 <panic>

0000000080003c80 <iget>:
{
    80003c80:	7179                	addi	sp,sp,-48
    80003c82:	f406                	sd	ra,40(sp)
    80003c84:	f022                	sd	s0,32(sp)
    80003c86:	ec26                	sd	s1,24(sp)
    80003c88:	e84a                	sd	s2,16(sp)
    80003c8a:	e44e                	sd	s3,8(sp)
    80003c8c:	e052                	sd	s4,0(sp)
    80003c8e:	1800                	addi	s0,sp,48
    80003c90:	89aa                	mv	s3,a0
    80003c92:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c94:	0023d517          	auipc	a0,0x23d
    80003c98:	c5c50513          	addi	a0,a0,-932 # 802408f0 <itable>
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	0de080e7          	jalr	222(ra) # 80000d7a <acquire>
  empty = 0;
    80003ca4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ca6:	0023d497          	auipc	s1,0x23d
    80003caa:	c6248493          	addi	s1,s1,-926 # 80240908 <itable+0x18>
    80003cae:	0023e697          	auipc	a3,0x23e
    80003cb2:	6ea68693          	addi	a3,a3,1770 # 80242398 <log>
    80003cb6:	a039                	j	80003cc4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cb8:	02090b63          	beqz	s2,80003cee <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003cbc:	08848493          	addi	s1,s1,136
    80003cc0:	02d48a63          	beq	s1,a3,80003cf4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003cc4:	449c                	lw	a5,8(s1)
    80003cc6:	fef059e3          	blez	a5,80003cb8 <iget+0x38>
    80003cca:	4098                	lw	a4,0(s1)
    80003ccc:	ff3716e3          	bne	a4,s3,80003cb8 <iget+0x38>
    80003cd0:	40d8                	lw	a4,4(s1)
    80003cd2:	ff4713e3          	bne	a4,s4,80003cb8 <iget+0x38>
      ip->ref++;
    80003cd6:	2785                	addiw	a5,a5,1
    80003cd8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003cda:	0023d517          	auipc	a0,0x23d
    80003cde:	c1650513          	addi	a0,a0,-1002 # 802408f0 <itable>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	14c080e7          	jalr	332(ra) # 80000e2e <release>
      return ip;
    80003cea:	8926                	mv	s2,s1
    80003cec:	a03d                	j	80003d1a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cee:	f7f9                	bnez	a5,80003cbc <iget+0x3c>
    80003cf0:	8926                	mv	s2,s1
    80003cf2:	b7e9                	j	80003cbc <iget+0x3c>
  if(empty == 0)
    80003cf4:	02090c63          	beqz	s2,80003d2c <iget+0xac>
  ip->dev = dev;
    80003cf8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003cfc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d00:	4785                	li	a5,1
    80003d02:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d06:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d0a:	0023d517          	auipc	a0,0x23d
    80003d0e:	be650513          	addi	a0,a0,-1050 # 802408f0 <itable>
    80003d12:	ffffd097          	auipc	ra,0xffffd
    80003d16:	11c080e7          	jalr	284(ra) # 80000e2e <release>
}
    80003d1a:	854a                	mv	a0,s2
    80003d1c:	70a2                	ld	ra,40(sp)
    80003d1e:	7402                	ld	s0,32(sp)
    80003d20:	64e2                	ld	s1,24(sp)
    80003d22:	6942                	ld	s2,16(sp)
    80003d24:	69a2                	ld	s3,8(sp)
    80003d26:	6a02                	ld	s4,0(sp)
    80003d28:	6145                	addi	sp,sp,48
    80003d2a:	8082                	ret
    panic("iget: no inodes");
    80003d2c:	00005517          	auipc	a0,0x5
    80003d30:	8ac50513          	addi	a0,a0,-1876 # 800085d8 <syscalls+0x168>
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	80c080e7          	jalr	-2036(ra) # 80000540 <panic>

0000000080003d3c <fsinit>:
fsinit(int dev) {
    80003d3c:	7179                	addi	sp,sp,-48
    80003d3e:	f406                	sd	ra,40(sp)
    80003d40:	f022                	sd	s0,32(sp)
    80003d42:	ec26                	sd	s1,24(sp)
    80003d44:	e84a                	sd	s2,16(sp)
    80003d46:	e44e                	sd	s3,8(sp)
    80003d48:	1800                	addi	s0,sp,48
    80003d4a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d4c:	4585                	li	a1,1
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	a54080e7          	jalr	-1452(ra) # 800037a2 <bread>
    80003d56:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d58:	0023d997          	auipc	s3,0x23d
    80003d5c:	b7898993          	addi	s3,s3,-1160 # 802408d0 <sb>
    80003d60:	02000613          	li	a2,32
    80003d64:	05850593          	addi	a1,a0,88
    80003d68:	854e                	mv	a0,s3
    80003d6a:	ffffd097          	auipc	ra,0xffffd
    80003d6e:	168080e7          	jalr	360(ra) # 80000ed2 <memmove>
  brelse(bp);
    80003d72:	8526                	mv	a0,s1
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	b5e080e7          	jalr	-1186(ra) # 800038d2 <brelse>
  if(sb.magic != FSMAGIC)
    80003d7c:	0009a703          	lw	a4,0(s3)
    80003d80:	102037b7          	lui	a5,0x10203
    80003d84:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d88:	02f71263          	bne	a4,a5,80003dac <fsinit+0x70>
  initlog(dev, &sb);
    80003d8c:	0023d597          	auipc	a1,0x23d
    80003d90:	b4458593          	addi	a1,a1,-1212 # 802408d0 <sb>
    80003d94:	854a                	mv	a0,s2
    80003d96:	00001097          	auipc	ra,0x1
    80003d9a:	b4a080e7          	jalr	-1206(ra) # 800048e0 <initlog>
}
    80003d9e:	70a2                	ld	ra,40(sp)
    80003da0:	7402                	ld	s0,32(sp)
    80003da2:	64e2                	ld	s1,24(sp)
    80003da4:	6942                	ld	s2,16(sp)
    80003da6:	69a2                	ld	s3,8(sp)
    80003da8:	6145                	addi	sp,sp,48
    80003daa:	8082                	ret
    panic("invalid file system");
    80003dac:	00005517          	auipc	a0,0x5
    80003db0:	83c50513          	addi	a0,a0,-1988 # 800085e8 <syscalls+0x178>
    80003db4:	ffffc097          	auipc	ra,0xffffc
    80003db8:	78c080e7          	jalr	1932(ra) # 80000540 <panic>

0000000080003dbc <iinit>:
{
    80003dbc:	7179                	addi	sp,sp,-48
    80003dbe:	f406                	sd	ra,40(sp)
    80003dc0:	f022                	sd	s0,32(sp)
    80003dc2:	ec26                	sd	s1,24(sp)
    80003dc4:	e84a                	sd	s2,16(sp)
    80003dc6:	e44e                	sd	s3,8(sp)
    80003dc8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003dca:	00005597          	auipc	a1,0x5
    80003dce:	83658593          	addi	a1,a1,-1994 # 80008600 <syscalls+0x190>
    80003dd2:	0023d517          	auipc	a0,0x23d
    80003dd6:	b1e50513          	addi	a0,a0,-1250 # 802408f0 <itable>
    80003dda:	ffffd097          	auipc	ra,0xffffd
    80003dde:	f10080e7          	jalr	-240(ra) # 80000cea <initlock>
  for(i = 0; i < NINODE; i++) {
    80003de2:	0023d497          	auipc	s1,0x23d
    80003de6:	b3648493          	addi	s1,s1,-1226 # 80240918 <itable+0x28>
    80003dea:	0023e997          	auipc	s3,0x23e
    80003dee:	5be98993          	addi	s3,s3,1470 # 802423a8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003df2:	00005917          	auipc	s2,0x5
    80003df6:	81690913          	addi	s2,s2,-2026 # 80008608 <syscalls+0x198>
    80003dfa:	85ca                	mv	a1,s2
    80003dfc:	8526                	mv	a0,s1
    80003dfe:	00001097          	auipc	ra,0x1
    80003e02:	e42080e7          	jalr	-446(ra) # 80004c40 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e06:	08848493          	addi	s1,s1,136
    80003e0a:	ff3498e3          	bne	s1,s3,80003dfa <iinit+0x3e>
}
    80003e0e:	70a2                	ld	ra,40(sp)
    80003e10:	7402                	ld	s0,32(sp)
    80003e12:	64e2                	ld	s1,24(sp)
    80003e14:	6942                	ld	s2,16(sp)
    80003e16:	69a2                	ld	s3,8(sp)
    80003e18:	6145                	addi	sp,sp,48
    80003e1a:	8082                	ret

0000000080003e1c <ialloc>:
{
    80003e1c:	715d                	addi	sp,sp,-80
    80003e1e:	e486                	sd	ra,72(sp)
    80003e20:	e0a2                	sd	s0,64(sp)
    80003e22:	fc26                	sd	s1,56(sp)
    80003e24:	f84a                	sd	s2,48(sp)
    80003e26:	f44e                	sd	s3,40(sp)
    80003e28:	f052                	sd	s4,32(sp)
    80003e2a:	ec56                	sd	s5,24(sp)
    80003e2c:	e85a                	sd	s6,16(sp)
    80003e2e:	e45e                	sd	s7,8(sp)
    80003e30:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e32:	0023d717          	auipc	a4,0x23d
    80003e36:	aaa72703          	lw	a4,-1366(a4) # 802408dc <sb+0xc>
    80003e3a:	4785                	li	a5,1
    80003e3c:	04e7fa63          	bgeu	a5,a4,80003e90 <ialloc+0x74>
    80003e40:	8aaa                	mv	s5,a0
    80003e42:	8bae                	mv	s7,a1
    80003e44:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e46:	0023da17          	auipc	s4,0x23d
    80003e4a:	a8aa0a13          	addi	s4,s4,-1398 # 802408d0 <sb>
    80003e4e:	00048b1b          	sext.w	s6,s1
    80003e52:	0044d593          	srli	a1,s1,0x4
    80003e56:	018a2783          	lw	a5,24(s4)
    80003e5a:	9dbd                	addw	a1,a1,a5
    80003e5c:	8556                	mv	a0,s5
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	944080e7          	jalr	-1724(ra) # 800037a2 <bread>
    80003e66:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e68:	05850993          	addi	s3,a0,88
    80003e6c:	00f4f793          	andi	a5,s1,15
    80003e70:	079a                	slli	a5,a5,0x6
    80003e72:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e74:	00099783          	lh	a5,0(s3)
    80003e78:	c3a1                	beqz	a5,80003eb8 <ialloc+0x9c>
    brelse(bp);
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	a58080e7          	jalr	-1448(ra) # 800038d2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e82:	0485                	addi	s1,s1,1
    80003e84:	00ca2703          	lw	a4,12(s4)
    80003e88:	0004879b          	sext.w	a5,s1
    80003e8c:	fce7e1e3          	bltu	a5,a4,80003e4e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003e90:	00004517          	auipc	a0,0x4
    80003e94:	78050513          	addi	a0,a0,1920 # 80008610 <syscalls+0x1a0>
    80003e98:	ffffc097          	auipc	ra,0xffffc
    80003e9c:	6f2080e7          	jalr	1778(ra) # 8000058a <printf>
  return 0;
    80003ea0:	4501                	li	a0,0
}
    80003ea2:	60a6                	ld	ra,72(sp)
    80003ea4:	6406                	ld	s0,64(sp)
    80003ea6:	74e2                	ld	s1,56(sp)
    80003ea8:	7942                	ld	s2,48(sp)
    80003eaa:	79a2                	ld	s3,40(sp)
    80003eac:	7a02                	ld	s4,32(sp)
    80003eae:	6ae2                	ld	s5,24(sp)
    80003eb0:	6b42                	ld	s6,16(sp)
    80003eb2:	6ba2                	ld	s7,8(sp)
    80003eb4:	6161                	addi	sp,sp,80
    80003eb6:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003eb8:	04000613          	li	a2,64
    80003ebc:	4581                	li	a1,0
    80003ebe:	854e                	mv	a0,s3
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	fb6080e7          	jalr	-74(ra) # 80000e76 <memset>
      dip->type = type;
    80003ec8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ecc:	854a                	mv	a0,s2
    80003ece:	00001097          	auipc	ra,0x1
    80003ed2:	c8e080e7          	jalr	-882(ra) # 80004b5c <log_write>
      brelse(bp);
    80003ed6:	854a                	mv	a0,s2
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	9fa080e7          	jalr	-1542(ra) # 800038d2 <brelse>
      return iget(dev, inum);
    80003ee0:	85da                	mv	a1,s6
    80003ee2:	8556                	mv	a0,s5
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	d9c080e7          	jalr	-612(ra) # 80003c80 <iget>
    80003eec:	bf5d                	j	80003ea2 <ialloc+0x86>

0000000080003eee <iupdate>:
{
    80003eee:	1101                	addi	sp,sp,-32
    80003ef0:	ec06                	sd	ra,24(sp)
    80003ef2:	e822                	sd	s0,16(sp)
    80003ef4:	e426                	sd	s1,8(sp)
    80003ef6:	e04a                	sd	s2,0(sp)
    80003ef8:	1000                	addi	s0,sp,32
    80003efa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003efc:	415c                	lw	a5,4(a0)
    80003efe:	0047d79b          	srliw	a5,a5,0x4
    80003f02:	0023d597          	auipc	a1,0x23d
    80003f06:	9e65a583          	lw	a1,-1562(a1) # 802408e8 <sb+0x18>
    80003f0a:	9dbd                	addw	a1,a1,a5
    80003f0c:	4108                	lw	a0,0(a0)
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	894080e7          	jalr	-1900(ra) # 800037a2 <bread>
    80003f16:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f18:	05850793          	addi	a5,a0,88
    80003f1c:	40d8                	lw	a4,4(s1)
    80003f1e:	8b3d                	andi	a4,a4,15
    80003f20:	071a                	slli	a4,a4,0x6
    80003f22:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003f24:	04449703          	lh	a4,68(s1)
    80003f28:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003f2c:	04649703          	lh	a4,70(s1)
    80003f30:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003f34:	04849703          	lh	a4,72(s1)
    80003f38:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003f3c:	04a49703          	lh	a4,74(s1)
    80003f40:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003f44:	44f8                	lw	a4,76(s1)
    80003f46:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f48:	03400613          	li	a2,52
    80003f4c:	05048593          	addi	a1,s1,80
    80003f50:	00c78513          	addi	a0,a5,12
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	f7e080e7          	jalr	-130(ra) # 80000ed2 <memmove>
  log_write(bp);
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	00001097          	auipc	ra,0x1
    80003f62:	bfe080e7          	jalr	-1026(ra) # 80004b5c <log_write>
  brelse(bp);
    80003f66:	854a                	mv	a0,s2
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	96a080e7          	jalr	-1686(ra) # 800038d2 <brelse>
}
    80003f70:	60e2                	ld	ra,24(sp)
    80003f72:	6442                	ld	s0,16(sp)
    80003f74:	64a2                	ld	s1,8(sp)
    80003f76:	6902                	ld	s2,0(sp)
    80003f78:	6105                	addi	sp,sp,32
    80003f7a:	8082                	ret

0000000080003f7c <idup>:
{
    80003f7c:	1101                	addi	sp,sp,-32
    80003f7e:	ec06                	sd	ra,24(sp)
    80003f80:	e822                	sd	s0,16(sp)
    80003f82:	e426                	sd	s1,8(sp)
    80003f84:	1000                	addi	s0,sp,32
    80003f86:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f88:	0023d517          	auipc	a0,0x23d
    80003f8c:	96850513          	addi	a0,a0,-1688 # 802408f0 <itable>
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	dea080e7          	jalr	-534(ra) # 80000d7a <acquire>
  ip->ref++;
    80003f98:	449c                	lw	a5,8(s1)
    80003f9a:	2785                	addiw	a5,a5,1
    80003f9c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f9e:	0023d517          	auipc	a0,0x23d
    80003fa2:	95250513          	addi	a0,a0,-1710 # 802408f0 <itable>
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	e88080e7          	jalr	-376(ra) # 80000e2e <release>
}
    80003fae:	8526                	mv	a0,s1
    80003fb0:	60e2                	ld	ra,24(sp)
    80003fb2:	6442                	ld	s0,16(sp)
    80003fb4:	64a2                	ld	s1,8(sp)
    80003fb6:	6105                	addi	sp,sp,32
    80003fb8:	8082                	ret

0000000080003fba <ilock>:
{
    80003fba:	1101                	addi	sp,sp,-32
    80003fbc:	ec06                	sd	ra,24(sp)
    80003fbe:	e822                	sd	s0,16(sp)
    80003fc0:	e426                	sd	s1,8(sp)
    80003fc2:	e04a                	sd	s2,0(sp)
    80003fc4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003fc6:	c115                	beqz	a0,80003fea <ilock+0x30>
    80003fc8:	84aa                	mv	s1,a0
    80003fca:	451c                	lw	a5,8(a0)
    80003fcc:	00f05f63          	blez	a5,80003fea <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fd0:	0541                	addi	a0,a0,16
    80003fd2:	00001097          	auipc	ra,0x1
    80003fd6:	ca8080e7          	jalr	-856(ra) # 80004c7a <acquiresleep>
  if(ip->valid == 0){
    80003fda:	40bc                	lw	a5,64(s1)
    80003fdc:	cf99                	beqz	a5,80003ffa <ilock+0x40>
}
    80003fde:	60e2                	ld	ra,24(sp)
    80003fe0:	6442                	ld	s0,16(sp)
    80003fe2:	64a2                	ld	s1,8(sp)
    80003fe4:	6902                	ld	s2,0(sp)
    80003fe6:	6105                	addi	sp,sp,32
    80003fe8:	8082                	ret
    panic("ilock");
    80003fea:	00004517          	auipc	a0,0x4
    80003fee:	63e50513          	addi	a0,a0,1598 # 80008628 <syscalls+0x1b8>
    80003ff2:	ffffc097          	auipc	ra,0xffffc
    80003ff6:	54e080e7          	jalr	1358(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ffa:	40dc                	lw	a5,4(s1)
    80003ffc:	0047d79b          	srliw	a5,a5,0x4
    80004000:	0023d597          	auipc	a1,0x23d
    80004004:	8e85a583          	lw	a1,-1816(a1) # 802408e8 <sb+0x18>
    80004008:	9dbd                	addw	a1,a1,a5
    8000400a:	4088                	lw	a0,0(s1)
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	796080e7          	jalr	1942(ra) # 800037a2 <bread>
    80004014:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004016:	05850593          	addi	a1,a0,88
    8000401a:	40dc                	lw	a5,4(s1)
    8000401c:	8bbd                	andi	a5,a5,15
    8000401e:	079a                	slli	a5,a5,0x6
    80004020:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004022:	00059783          	lh	a5,0(a1)
    80004026:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000402a:	00259783          	lh	a5,2(a1)
    8000402e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004032:	00459783          	lh	a5,4(a1)
    80004036:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000403a:	00659783          	lh	a5,6(a1)
    8000403e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004042:	459c                	lw	a5,8(a1)
    80004044:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004046:	03400613          	li	a2,52
    8000404a:	05b1                	addi	a1,a1,12
    8000404c:	05048513          	addi	a0,s1,80
    80004050:	ffffd097          	auipc	ra,0xffffd
    80004054:	e82080e7          	jalr	-382(ra) # 80000ed2 <memmove>
    brelse(bp);
    80004058:	854a                	mv	a0,s2
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	878080e7          	jalr	-1928(ra) # 800038d2 <brelse>
    ip->valid = 1;
    80004062:	4785                	li	a5,1
    80004064:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004066:	04449783          	lh	a5,68(s1)
    8000406a:	fbb5                	bnez	a5,80003fde <ilock+0x24>
      panic("ilock: no type");
    8000406c:	00004517          	auipc	a0,0x4
    80004070:	5c450513          	addi	a0,a0,1476 # 80008630 <syscalls+0x1c0>
    80004074:	ffffc097          	auipc	ra,0xffffc
    80004078:	4cc080e7          	jalr	1228(ra) # 80000540 <panic>

000000008000407c <iunlock>:
{
    8000407c:	1101                	addi	sp,sp,-32
    8000407e:	ec06                	sd	ra,24(sp)
    80004080:	e822                	sd	s0,16(sp)
    80004082:	e426                	sd	s1,8(sp)
    80004084:	e04a                	sd	s2,0(sp)
    80004086:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004088:	c905                	beqz	a0,800040b8 <iunlock+0x3c>
    8000408a:	84aa                	mv	s1,a0
    8000408c:	01050913          	addi	s2,a0,16
    80004090:	854a                	mv	a0,s2
    80004092:	00001097          	auipc	ra,0x1
    80004096:	c82080e7          	jalr	-894(ra) # 80004d14 <holdingsleep>
    8000409a:	cd19                	beqz	a0,800040b8 <iunlock+0x3c>
    8000409c:	449c                	lw	a5,8(s1)
    8000409e:	00f05d63          	blez	a5,800040b8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800040a2:	854a                	mv	a0,s2
    800040a4:	00001097          	auipc	ra,0x1
    800040a8:	c2c080e7          	jalr	-980(ra) # 80004cd0 <releasesleep>
}
    800040ac:	60e2                	ld	ra,24(sp)
    800040ae:	6442                	ld	s0,16(sp)
    800040b0:	64a2                	ld	s1,8(sp)
    800040b2:	6902                	ld	s2,0(sp)
    800040b4:	6105                	addi	sp,sp,32
    800040b6:	8082                	ret
    panic("iunlock");
    800040b8:	00004517          	auipc	a0,0x4
    800040bc:	58850513          	addi	a0,a0,1416 # 80008640 <syscalls+0x1d0>
    800040c0:	ffffc097          	auipc	ra,0xffffc
    800040c4:	480080e7          	jalr	1152(ra) # 80000540 <panic>

00000000800040c8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040c8:	7179                	addi	sp,sp,-48
    800040ca:	f406                	sd	ra,40(sp)
    800040cc:	f022                	sd	s0,32(sp)
    800040ce:	ec26                	sd	s1,24(sp)
    800040d0:	e84a                	sd	s2,16(sp)
    800040d2:	e44e                	sd	s3,8(sp)
    800040d4:	e052                	sd	s4,0(sp)
    800040d6:	1800                	addi	s0,sp,48
    800040d8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040da:	05050493          	addi	s1,a0,80
    800040de:	08050913          	addi	s2,a0,128
    800040e2:	a021                	j	800040ea <itrunc+0x22>
    800040e4:	0491                	addi	s1,s1,4
    800040e6:	01248d63          	beq	s1,s2,80004100 <itrunc+0x38>
    if(ip->addrs[i]){
    800040ea:	408c                	lw	a1,0(s1)
    800040ec:	dde5                	beqz	a1,800040e4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040ee:	0009a503          	lw	a0,0(s3)
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	8f6080e7          	jalr	-1802(ra) # 800039e8 <bfree>
      ip->addrs[i] = 0;
    800040fa:	0004a023          	sw	zero,0(s1)
    800040fe:	b7dd                	j	800040e4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004100:	0809a583          	lw	a1,128(s3)
    80004104:	e185                	bnez	a1,80004124 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004106:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000410a:	854e                	mv	a0,s3
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	de2080e7          	jalr	-542(ra) # 80003eee <iupdate>
}
    80004114:	70a2                	ld	ra,40(sp)
    80004116:	7402                	ld	s0,32(sp)
    80004118:	64e2                	ld	s1,24(sp)
    8000411a:	6942                	ld	s2,16(sp)
    8000411c:	69a2                	ld	s3,8(sp)
    8000411e:	6a02                	ld	s4,0(sp)
    80004120:	6145                	addi	sp,sp,48
    80004122:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004124:	0009a503          	lw	a0,0(s3)
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	67a080e7          	jalr	1658(ra) # 800037a2 <bread>
    80004130:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004132:	05850493          	addi	s1,a0,88
    80004136:	45850913          	addi	s2,a0,1112
    8000413a:	a021                	j	80004142 <itrunc+0x7a>
    8000413c:	0491                	addi	s1,s1,4
    8000413e:	01248b63          	beq	s1,s2,80004154 <itrunc+0x8c>
      if(a[j])
    80004142:	408c                	lw	a1,0(s1)
    80004144:	dde5                	beqz	a1,8000413c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004146:	0009a503          	lw	a0,0(s3)
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	89e080e7          	jalr	-1890(ra) # 800039e8 <bfree>
    80004152:	b7ed                	j	8000413c <itrunc+0x74>
    brelse(bp);
    80004154:	8552                	mv	a0,s4
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	77c080e7          	jalr	1916(ra) # 800038d2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000415e:	0809a583          	lw	a1,128(s3)
    80004162:	0009a503          	lw	a0,0(s3)
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	882080e7          	jalr	-1918(ra) # 800039e8 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000416e:	0809a023          	sw	zero,128(s3)
    80004172:	bf51                	j	80004106 <itrunc+0x3e>

0000000080004174 <iput>:
{
    80004174:	1101                	addi	sp,sp,-32
    80004176:	ec06                	sd	ra,24(sp)
    80004178:	e822                	sd	s0,16(sp)
    8000417a:	e426                	sd	s1,8(sp)
    8000417c:	e04a                	sd	s2,0(sp)
    8000417e:	1000                	addi	s0,sp,32
    80004180:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004182:	0023c517          	auipc	a0,0x23c
    80004186:	76e50513          	addi	a0,a0,1902 # 802408f0 <itable>
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	bf0080e7          	jalr	-1040(ra) # 80000d7a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004192:	4498                	lw	a4,8(s1)
    80004194:	4785                	li	a5,1
    80004196:	02f70363          	beq	a4,a5,800041bc <iput+0x48>
  ip->ref--;
    8000419a:	449c                	lw	a5,8(s1)
    8000419c:	37fd                	addiw	a5,a5,-1
    8000419e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800041a0:	0023c517          	auipc	a0,0x23c
    800041a4:	75050513          	addi	a0,a0,1872 # 802408f0 <itable>
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	c86080e7          	jalr	-890(ra) # 80000e2e <release>
}
    800041b0:	60e2                	ld	ra,24(sp)
    800041b2:	6442                	ld	s0,16(sp)
    800041b4:	64a2                	ld	s1,8(sp)
    800041b6:	6902                	ld	s2,0(sp)
    800041b8:	6105                	addi	sp,sp,32
    800041ba:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041bc:	40bc                	lw	a5,64(s1)
    800041be:	dff1                	beqz	a5,8000419a <iput+0x26>
    800041c0:	04a49783          	lh	a5,74(s1)
    800041c4:	fbf9                	bnez	a5,8000419a <iput+0x26>
    acquiresleep(&ip->lock);
    800041c6:	01048913          	addi	s2,s1,16
    800041ca:	854a                	mv	a0,s2
    800041cc:	00001097          	auipc	ra,0x1
    800041d0:	aae080e7          	jalr	-1362(ra) # 80004c7a <acquiresleep>
    release(&itable.lock);
    800041d4:	0023c517          	auipc	a0,0x23c
    800041d8:	71c50513          	addi	a0,a0,1820 # 802408f0 <itable>
    800041dc:	ffffd097          	auipc	ra,0xffffd
    800041e0:	c52080e7          	jalr	-942(ra) # 80000e2e <release>
    itrunc(ip);
    800041e4:	8526                	mv	a0,s1
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	ee2080e7          	jalr	-286(ra) # 800040c8 <itrunc>
    ip->type = 0;
    800041ee:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041f2:	8526                	mv	a0,s1
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	cfa080e7          	jalr	-774(ra) # 80003eee <iupdate>
    ip->valid = 0;
    800041fc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004200:	854a                	mv	a0,s2
    80004202:	00001097          	auipc	ra,0x1
    80004206:	ace080e7          	jalr	-1330(ra) # 80004cd0 <releasesleep>
    acquire(&itable.lock);
    8000420a:	0023c517          	auipc	a0,0x23c
    8000420e:	6e650513          	addi	a0,a0,1766 # 802408f0 <itable>
    80004212:	ffffd097          	auipc	ra,0xffffd
    80004216:	b68080e7          	jalr	-1176(ra) # 80000d7a <acquire>
    8000421a:	b741                	j	8000419a <iput+0x26>

000000008000421c <iunlockput>:
{
    8000421c:	1101                	addi	sp,sp,-32
    8000421e:	ec06                	sd	ra,24(sp)
    80004220:	e822                	sd	s0,16(sp)
    80004222:	e426                	sd	s1,8(sp)
    80004224:	1000                	addi	s0,sp,32
    80004226:	84aa                	mv	s1,a0
  iunlock(ip);
    80004228:	00000097          	auipc	ra,0x0
    8000422c:	e54080e7          	jalr	-428(ra) # 8000407c <iunlock>
  iput(ip);
    80004230:	8526                	mv	a0,s1
    80004232:	00000097          	auipc	ra,0x0
    80004236:	f42080e7          	jalr	-190(ra) # 80004174 <iput>
}
    8000423a:	60e2                	ld	ra,24(sp)
    8000423c:	6442                	ld	s0,16(sp)
    8000423e:	64a2                	ld	s1,8(sp)
    80004240:	6105                	addi	sp,sp,32
    80004242:	8082                	ret

0000000080004244 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004244:	1141                	addi	sp,sp,-16
    80004246:	e422                	sd	s0,8(sp)
    80004248:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000424a:	411c                	lw	a5,0(a0)
    8000424c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000424e:	415c                	lw	a5,4(a0)
    80004250:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004252:	04451783          	lh	a5,68(a0)
    80004256:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000425a:	04a51783          	lh	a5,74(a0)
    8000425e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004262:	04c56783          	lwu	a5,76(a0)
    80004266:	e99c                	sd	a5,16(a1)
}
    80004268:	6422                	ld	s0,8(sp)
    8000426a:	0141                	addi	sp,sp,16
    8000426c:	8082                	ret

000000008000426e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000426e:	457c                	lw	a5,76(a0)
    80004270:	0ed7e963          	bltu	a5,a3,80004362 <readi+0xf4>
{
    80004274:	7159                	addi	sp,sp,-112
    80004276:	f486                	sd	ra,104(sp)
    80004278:	f0a2                	sd	s0,96(sp)
    8000427a:	eca6                	sd	s1,88(sp)
    8000427c:	e8ca                	sd	s2,80(sp)
    8000427e:	e4ce                	sd	s3,72(sp)
    80004280:	e0d2                	sd	s4,64(sp)
    80004282:	fc56                	sd	s5,56(sp)
    80004284:	f85a                	sd	s6,48(sp)
    80004286:	f45e                	sd	s7,40(sp)
    80004288:	f062                	sd	s8,32(sp)
    8000428a:	ec66                	sd	s9,24(sp)
    8000428c:	e86a                	sd	s10,16(sp)
    8000428e:	e46e                	sd	s11,8(sp)
    80004290:	1880                	addi	s0,sp,112
    80004292:	8b2a                	mv	s6,a0
    80004294:	8bae                	mv	s7,a1
    80004296:	8a32                	mv	s4,a2
    80004298:	84b6                	mv	s1,a3
    8000429a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000429c:	9f35                	addw	a4,a4,a3
    return 0;
    8000429e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800042a0:	0ad76063          	bltu	a4,a3,80004340 <readi+0xd2>
  if(off + n > ip->size)
    800042a4:	00e7f463          	bgeu	a5,a4,800042ac <readi+0x3e>
    n = ip->size - off;
    800042a8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042ac:	0a0a8963          	beqz	s5,8000435e <readi+0xf0>
    800042b0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800042b2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800042b6:	5c7d                	li	s8,-1
    800042b8:	a82d                	j	800042f2 <readi+0x84>
    800042ba:	020d1d93          	slli	s11,s10,0x20
    800042be:	020ddd93          	srli	s11,s11,0x20
    800042c2:	05890613          	addi	a2,s2,88
    800042c6:	86ee                	mv	a3,s11
    800042c8:	963a                	add	a2,a2,a4
    800042ca:	85d2                	mv	a1,s4
    800042cc:	855e                	mv	a0,s7
    800042ce:	ffffe097          	auipc	ra,0xffffe
    800042d2:	496080e7          	jalr	1174(ra) # 80002764 <either_copyout>
    800042d6:	05850d63          	beq	a0,s8,80004330 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042da:	854a                	mv	a0,s2
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	5f6080e7          	jalr	1526(ra) # 800038d2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042e4:	013d09bb          	addw	s3,s10,s3
    800042e8:	009d04bb          	addw	s1,s10,s1
    800042ec:	9a6e                	add	s4,s4,s11
    800042ee:	0559f763          	bgeu	s3,s5,8000433c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800042f2:	00a4d59b          	srliw	a1,s1,0xa
    800042f6:	855a                	mv	a0,s6
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	89e080e7          	jalr	-1890(ra) # 80003b96 <bmap>
    80004300:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004304:	cd85                	beqz	a1,8000433c <readi+0xce>
    bp = bread(ip->dev, addr);
    80004306:	000b2503          	lw	a0,0(s6)
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	498080e7          	jalr	1176(ra) # 800037a2 <bread>
    80004312:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004314:	3ff4f713          	andi	a4,s1,1023
    80004318:	40ec87bb          	subw	a5,s9,a4
    8000431c:	413a86bb          	subw	a3,s5,s3
    80004320:	8d3e                	mv	s10,a5
    80004322:	2781                	sext.w	a5,a5
    80004324:	0006861b          	sext.w	a2,a3
    80004328:	f8f679e3          	bgeu	a2,a5,800042ba <readi+0x4c>
    8000432c:	8d36                	mv	s10,a3
    8000432e:	b771                	j	800042ba <readi+0x4c>
      brelse(bp);
    80004330:	854a                	mv	a0,s2
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	5a0080e7          	jalr	1440(ra) # 800038d2 <brelse>
      tot = -1;
    8000433a:	59fd                	li	s3,-1
  }
  return tot;
    8000433c:	0009851b          	sext.w	a0,s3
}
    80004340:	70a6                	ld	ra,104(sp)
    80004342:	7406                	ld	s0,96(sp)
    80004344:	64e6                	ld	s1,88(sp)
    80004346:	6946                	ld	s2,80(sp)
    80004348:	69a6                	ld	s3,72(sp)
    8000434a:	6a06                	ld	s4,64(sp)
    8000434c:	7ae2                	ld	s5,56(sp)
    8000434e:	7b42                	ld	s6,48(sp)
    80004350:	7ba2                	ld	s7,40(sp)
    80004352:	7c02                	ld	s8,32(sp)
    80004354:	6ce2                	ld	s9,24(sp)
    80004356:	6d42                	ld	s10,16(sp)
    80004358:	6da2                	ld	s11,8(sp)
    8000435a:	6165                	addi	sp,sp,112
    8000435c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000435e:	89d6                	mv	s3,s5
    80004360:	bff1                	j	8000433c <readi+0xce>
    return 0;
    80004362:	4501                	li	a0,0
}
    80004364:	8082                	ret

0000000080004366 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004366:	457c                	lw	a5,76(a0)
    80004368:	10d7e863          	bltu	a5,a3,80004478 <writei+0x112>
{
    8000436c:	7159                	addi	sp,sp,-112
    8000436e:	f486                	sd	ra,104(sp)
    80004370:	f0a2                	sd	s0,96(sp)
    80004372:	eca6                	sd	s1,88(sp)
    80004374:	e8ca                	sd	s2,80(sp)
    80004376:	e4ce                	sd	s3,72(sp)
    80004378:	e0d2                	sd	s4,64(sp)
    8000437a:	fc56                	sd	s5,56(sp)
    8000437c:	f85a                	sd	s6,48(sp)
    8000437e:	f45e                	sd	s7,40(sp)
    80004380:	f062                	sd	s8,32(sp)
    80004382:	ec66                	sd	s9,24(sp)
    80004384:	e86a                	sd	s10,16(sp)
    80004386:	e46e                	sd	s11,8(sp)
    80004388:	1880                	addi	s0,sp,112
    8000438a:	8aaa                	mv	s5,a0
    8000438c:	8bae                	mv	s7,a1
    8000438e:	8a32                	mv	s4,a2
    80004390:	8936                	mv	s2,a3
    80004392:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004394:	00e687bb          	addw	a5,a3,a4
    80004398:	0ed7e263          	bltu	a5,a3,8000447c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000439c:	00043737          	lui	a4,0x43
    800043a0:	0ef76063          	bltu	a4,a5,80004480 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043a4:	0c0b0863          	beqz	s6,80004474 <writei+0x10e>
    800043a8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800043aa:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800043ae:	5c7d                	li	s8,-1
    800043b0:	a091                	j	800043f4 <writei+0x8e>
    800043b2:	020d1d93          	slli	s11,s10,0x20
    800043b6:	020ddd93          	srli	s11,s11,0x20
    800043ba:	05848513          	addi	a0,s1,88
    800043be:	86ee                	mv	a3,s11
    800043c0:	8652                	mv	a2,s4
    800043c2:	85de                	mv	a1,s7
    800043c4:	953a                	add	a0,a0,a4
    800043c6:	ffffe097          	auipc	ra,0xffffe
    800043ca:	3f4080e7          	jalr	1012(ra) # 800027ba <either_copyin>
    800043ce:	07850263          	beq	a0,s8,80004432 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043d2:	8526                	mv	a0,s1
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	788080e7          	jalr	1928(ra) # 80004b5c <log_write>
    brelse(bp);
    800043dc:	8526                	mv	a0,s1
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	4f4080e7          	jalr	1268(ra) # 800038d2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043e6:	013d09bb          	addw	s3,s10,s3
    800043ea:	012d093b          	addw	s2,s10,s2
    800043ee:	9a6e                	add	s4,s4,s11
    800043f0:	0569f663          	bgeu	s3,s6,8000443c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800043f4:	00a9559b          	srliw	a1,s2,0xa
    800043f8:	8556                	mv	a0,s5
    800043fa:	fffff097          	auipc	ra,0xfffff
    800043fe:	79c080e7          	jalr	1948(ra) # 80003b96 <bmap>
    80004402:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004406:	c99d                	beqz	a1,8000443c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004408:	000aa503          	lw	a0,0(s5)
    8000440c:	fffff097          	auipc	ra,0xfffff
    80004410:	396080e7          	jalr	918(ra) # 800037a2 <bread>
    80004414:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004416:	3ff97713          	andi	a4,s2,1023
    8000441a:	40ec87bb          	subw	a5,s9,a4
    8000441e:	413b06bb          	subw	a3,s6,s3
    80004422:	8d3e                	mv	s10,a5
    80004424:	2781                	sext.w	a5,a5
    80004426:	0006861b          	sext.w	a2,a3
    8000442a:	f8f674e3          	bgeu	a2,a5,800043b2 <writei+0x4c>
    8000442e:	8d36                	mv	s10,a3
    80004430:	b749                	j	800043b2 <writei+0x4c>
      brelse(bp);
    80004432:	8526                	mv	a0,s1
    80004434:	fffff097          	auipc	ra,0xfffff
    80004438:	49e080e7          	jalr	1182(ra) # 800038d2 <brelse>
  }

  if(off > ip->size)
    8000443c:	04caa783          	lw	a5,76(s5)
    80004440:	0127f463          	bgeu	a5,s2,80004448 <writei+0xe2>
    ip->size = off;
    80004444:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004448:	8556                	mv	a0,s5
    8000444a:	00000097          	auipc	ra,0x0
    8000444e:	aa4080e7          	jalr	-1372(ra) # 80003eee <iupdate>

  return tot;
    80004452:	0009851b          	sext.w	a0,s3
}
    80004456:	70a6                	ld	ra,104(sp)
    80004458:	7406                	ld	s0,96(sp)
    8000445a:	64e6                	ld	s1,88(sp)
    8000445c:	6946                	ld	s2,80(sp)
    8000445e:	69a6                	ld	s3,72(sp)
    80004460:	6a06                	ld	s4,64(sp)
    80004462:	7ae2                	ld	s5,56(sp)
    80004464:	7b42                	ld	s6,48(sp)
    80004466:	7ba2                	ld	s7,40(sp)
    80004468:	7c02                	ld	s8,32(sp)
    8000446a:	6ce2                	ld	s9,24(sp)
    8000446c:	6d42                	ld	s10,16(sp)
    8000446e:	6da2                	ld	s11,8(sp)
    80004470:	6165                	addi	sp,sp,112
    80004472:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004474:	89da                	mv	s3,s6
    80004476:	bfc9                	j	80004448 <writei+0xe2>
    return -1;
    80004478:	557d                	li	a0,-1
}
    8000447a:	8082                	ret
    return -1;
    8000447c:	557d                	li	a0,-1
    8000447e:	bfe1                	j	80004456 <writei+0xf0>
    return -1;
    80004480:	557d                	li	a0,-1
    80004482:	bfd1                	j	80004456 <writei+0xf0>

0000000080004484 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004484:	1141                	addi	sp,sp,-16
    80004486:	e406                	sd	ra,8(sp)
    80004488:	e022                	sd	s0,0(sp)
    8000448a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000448c:	4639                	li	a2,14
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	ab8080e7          	jalr	-1352(ra) # 80000f46 <strncmp>
}
    80004496:	60a2                	ld	ra,8(sp)
    80004498:	6402                	ld	s0,0(sp)
    8000449a:	0141                	addi	sp,sp,16
    8000449c:	8082                	ret

000000008000449e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000449e:	7139                	addi	sp,sp,-64
    800044a0:	fc06                	sd	ra,56(sp)
    800044a2:	f822                	sd	s0,48(sp)
    800044a4:	f426                	sd	s1,40(sp)
    800044a6:	f04a                	sd	s2,32(sp)
    800044a8:	ec4e                	sd	s3,24(sp)
    800044aa:	e852                	sd	s4,16(sp)
    800044ac:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800044ae:	04451703          	lh	a4,68(a0)
    800044b2:	4785                	li	a5,1
    800044b4:	00f71a63          	bne	a4,a5,800044c8 <dirlookup+0x2a>
    800044b8:	892a                	mv	s2,a0
    800044ba:	89ae                	mv	s3,a1
    800044bc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044be:	457c                	lw	a5,76(a0)
    800044c0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044c2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044c4:	e79d                	bnez	a5,800044f2 <dirlookup+0x54>
    800044c6:	a8a5                	j	8000453e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044c8:	00004517          	auipc	a0,0x4
    800044cc:	18050513          	addi	a0,a0,384 # 80008648 <syscalls+0x1d8>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	070080e7          	jalr	112(ra) # 80000540 <panic>
      panic("dirlookup read");
    800044d8:	00004517          	auipc	a0,0x4
    800044dc:	18850513          	addi	a0,a0,392 # 80008660 <syscalls+0x1f0>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	060080e7          	jalr	96(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044e8:	24c1                	addiw	s1,s1,16
    800044ea:	04c92783          	lw	a5,76(s2)
    800044ee:	04f4f763          	bgeu	s1,a5,8000453c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044f2:	4741                	li	a4,16
    800044f4:	86a6                	mv	a3,s1
    800044f6:	fc040613          	addi	a2,s0,-64
    800044fa:	4581                	li	a1,0
    800044fc:	854a                	mv	a0,s2
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	d70080e7          	jalr	-656(ra) # 8000426e <readi>
    80004506:	47c1                	li	a5,16
    80004508:	fcf518e3          	bne	a0,a5,800044d8 <dirlookup+0x3a>
    if(de.inum == 0)
    8000450c:	fc045783          	lhu	a5,-64(s0)
    80004510:	dfe1                	beqz	a5,800044e8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004512:	fc240593          	addi	a1,s0,-62
    80004516:	854e                	mv	a0,s3
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	f6c080e7          	jalr	-148(ra) # 80004484 <namecmp>
    80004520:	f561                	bnez	a0,800044e8 <dirlookup+0x4a>
      if(poff)
    80004522:	000a0463          	beqz	s4,8000452a <dirlookup+0x8c>
        *poff = off;
    80004526:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000452a:	fc045583          	lhu	a1,-64(s0)
    8000452e:	00092503          	lw	a0,0(s2)
    80004532:	fffff097          	auipc	ra,0xfffff
    80004536:	74e080e7          	jalr	1870(ra) # 80003c80 <iget>
    8000453a:	a011                	j	8000453e <dirlookup+0xa0>
  return 0;
    8000453c:	4501                	li	a0,0
}
    8000453e:	70e2                	ld	ra,56(sp)
    80004540:	7442                	ld	s0,48(sp)
    80004542:	74a2                	ld	s1,40(sp)
    80004544:	7902                	ld	s2,32(sp)
    80004546:	69e2                	ld	s3,24(sp)
    80004548:	6a42                	ld	s4,16(sp)
    8000454a:	6121                	addi	sp,sp,64
    8000454c:	8082                	ret

000000008000454e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000454e:	711d                	addi	sp,sp,-96
    80004550:	ec86                	sd	ra,88(sp)
    80004552:	e8a2                	sd	s0,80(sp)
    80004554:	e4a6                	sd	s1,72(sp)
    80004556:	e0ca                	sd	s2,64(sp)
    80004558:	fc4e                	sd	s3,56(sp)
    8000455a:	f852                	sd	s4,48(sp)
    8000455c:	f456                	sd	s5,40(sp)
    8000455e:	f05a                	sd	s6,32(sp)
    80004560:	ec5e                	sd	s7,24(sp)
    80004562:	e862                	sd	s8,16(sp)
    80004564:	e466                	sd	s9,8(sp)
    80004566:	e06a                	sd	s10,0(sp)
    80004568:	1080                	addi	s0,sp,96
    8000456a:	84aa                	mv	s1,a0
    8000456c:	8b2e                	mv	s6,a1
    8000456e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004570:	00054703          	lbu	a4,0(a0)
    80004574:	02f00793          	li	a5,47
    80004578:	02f70363          	beq	a4,a5,8000459e <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000457c:	ffffd097          	auipc	ra,0xffffd
    80004580:	616080e7          	jalr	1558(ra) # 80001b92 <myproc>
    80004584:	15053503          	ld	a0,336(a0)
    80004588:	00000097          	auipc	ra,0x0
    8000458c:	9f4080e7          	jalr	-1548(ra) # 80003f7c <idup>
    80004590:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004592:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004596:	4cb5                	li	s9,13
  len = path - s;
    80004598:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000459a:	4c05                	li	s8,1
    8000459c:	a87d                	j	8000465a <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    8000459e:	4585                	li	a1,1
    800045a0:	4505                	li	a0,1
    800045a2:	fffff097          	auipc	ra,0xfffff
    800045a6:	6de080e7          	jalr	1758(ra) # 80003c80 <iget>
    800045aa:	8a2a                	mv	s4,a0
    800045ac:	b7dd                	j	80004592 <namex+0x44>
      iunlockput(ip);
    800045ae:	8552                	mv	a0,s4
    800045b0:	00000097          	auipc	ra,0x0
    800045b4:	c6c080e7          	jalr	-916(ra) # 8000421c <iunlockput>
      return 0;
    800045b8:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800045ba:	8552                	mv	a0,s4
    800045bc:	60e6                	ld	ra,88(sp)
    800045be:	6446                	ld	s0,80(sp)
    800045c0:	64a6                	ld	s1,72(sp)
    800045c2:	6906                	ld	s2,64(sp)
    800045c4:	79e2                	ld	s3,56(sp)
    800045c6:	7a42                	ld	s4,48(sp)
    800045c8:	7aa2                	ld	s5,40(sp)
    800045ca:	7b02                	ld	s6,32(sp)
    800045cc:	6be2                	ld	s7,24(sp)
    800045ce:	6c42                	ld	s8,16(sp)
    800045d0:	6ca2                	ld	s9,8(sp)
    800045d2:	6d02                	ld	s10,0(sp)
    800045d4:	6125                	addi	sp,sp,96
    800045d6:	8082                	ret
      iunlock(ip);
    800045d8:	8552                	mv	a0,s4
    800045da:	00000097          	auipc	ra,0x0
    800045de:	aa2080e7          	jalr	-1374(ra) # 8000407c <iunlock>
      return ip;
    800045e2:	bfe1                	j	800045ba <namex+0x6c>
      iunlockput(ip);
    800045e4:	8552                	mv	a0,s4
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	c36080e7          	jalr	-970(ra) # 8000421c <iunlockput>
      return 0;
    800045ee:	8a4e                	mv	s4,s3
    800045f0:	b7e9                	j	800045ba <namex+0x6c>
  len = path - s;
    800045f2:	40998633          	sub	a2,s3,s1
    800045f6:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800045fa:	09acd863          	bge	s9,s10,8000468a <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800045fe:	4639                	li	a2,14
    80004600:	85a6                	mv	a1,s1
    80004602:	8556                	mv	a0,s5
    80004604:	ffffd097          	auipc	ra,0xffffd
    80004608:	8ce080e7          	jalr	-1842(ra) # 80000ed2 <memmove>
    8000460c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000460e:	0004c783          	lbu	a5,0(s1)
    80004612:	01279763          	bne	a5,s2,80004620 <namex+0xd2>
    path++;
    80004616:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004618:	0004c783          	lbu	a5,0(s1)
    8000461c:	ff278de3          	beq	a5,s2,80004616 <namex+0xc8>
    ilock(ip);
    80004620:	8552                	mv	a0,s4
    80004622:	00000097          	auipc	ra,0x0
    80004626:	998080e7          	jalr	-1640(ra) # 80003fba <ilock>
    if(ip->type != T_DIR){
    8000462a:	044a1783          	lh	a5,68(s4)
    8000462e:	f98790e3          	bne	a5,s8,800045ae <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004632:	000b0563          	beqz	s6,8000463c <namex+0xee>
    80004636:	0004c783          	lbu	a5,0(s1)
    8000463a:	dfd9                	beqz	a5,800045d8 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000463c:	865e                	mv	a2,s7
    8000463e:	85d6                	mv	a1,s5
    80004640:	8552                	mv	a0,s4
    80004642:	00000097          	auipc	ra,0x0
    80004646:	e5c080e7          	jalr	-420(ra) # 8000449e <dirlookup>
    8000464a:	89aa                	mv	s3,a0
    8000464c:	dd41                	beqz	a0,800045e4 <namex+0x96>
    iunlockput(ip);
    8000464e:	8552                	mv	a0,s4
    80004650:	00000097          	auipc	ra,0x0
    80004654:	bcc080e7          	jalr	-1076(ra) # 8000421c <iunlockput>
    ip = next;
    80004658:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000465a:	0004c783          	lbu	a5,0(s1)
    8000465e:	01279763          	bne	a5,s2,8000466c <namex+0x11e>
    path++;
    80004662:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004664:	0004c783          	lbu	a5,0(s1)
    80004668:	ff278de3          	beq	a5,s2,80004662 <namex+0x114>
  if(*path == 0)
    8000466c:	cb9d                	beqz	a5,800046a2 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000466e:	0004c783          	lbu	a5,0(s1)
    80004672:	89a6                	mv	s3,s1
  len = path - s;
    80004674:	8d5e                	mv	s10,s7
    80004676:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004678:	01278963          	beq	a5,s2,8000468a <namex+0x13c>
    8000467c:	dbbd                	beqz	a5,800045f2 <namex+0xa4>
    path++;
    8000467e:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004680:	0009c783          	lbu	a5,0(s3)
    80004684:	ff279ce3          	bne	a5,s2,8000467c <namex+0x12e>
    80004688:	b7ad                	j	800045f2 <namex+0xa4>
    memmove(name, s, len);
    8000468a:	2601                	sext.w	a2,a2
    8000468c:	85a6                	mv	a1,s1
    8000468e:	8556                	mv	a0,s5
    80004690:	ffffd097          	auipc	ra,0xffffd
    80004694:	842080e7          	jalr	-1982(ra) # 80000ed2 <memmove>
    name[len] = 0;
    80004698:	9d56                	add	s10,s10,s5
    8000469a:	000d0023          	sb	zero,0(s10)
    8000469e:	84ce                	mv	s1,s3
    800046a0:	b7bd                	j	8000460e <namex+0xc0>
  if(nameiparent){
    800046a2:	f00b0ce3          	beqz	s6,800045ba <namex+0x6c>
    iput(ip);
    800046a6:	8552                	mv	a0,s4
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	acc080e7          	jalr	-1332(ra) # 80004174 <iput>
    return 0;
    800046b0:	4a01                	li	s4,0
    800046b2:	b721                	j	800045ba <namex+0x6c>

00000000800046b4 <dirlink>:
{
    800046b4:	7139                	addi	sp,sp,-64
    800046b6:	fc06                	sd	ra,56(sp)
    800046b8:	f822                	sd	s0,48(sp)
    800046ba:	f426                	sd	s1,40(sp)
    800046bc:	f04a                	sd	s2,32(sp)
    800046be:	ec4e                	sd	s3,24(sp)
    800046c0:	e852                	sd	s4,16(sp)
    800046c2:	0080                	addi	s0,sp,64
    800046c4:	892a                	mv	s2,a0
    800046c6:	8a2e                	mv	s4,a1
    800046c8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046ca:	4601                	li	a2,0
    800046cc:	00000097          	auipc	ra,0x0
    800046d0:	dd2080e7          	jalr	-558(ra) # 8000449e <dirlookup>
    800046d4:	e93d                	bnez	a0,8000474a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046d6:	04c92483          	lw	s1,76(s2)
    800046da:	c49d                	beqz	s1,80004708 <dirlink+0x54>
    800046dc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046de:	4741                	li	a4,16
    800046e0:	86a6                	mv	a3,s1
    800046e2:	fc040613          	addi	a2,s0,-64
    800046e6:	4581                	li	a1,0
    800046e8:	854a                	mv	a0,s2
    800046ea:	00000097          	auipc	ra,0x0
    800046ee:	b84080e7          	jalr	-1148(ra) # 8000426e <readi>
    800046f2:	47c1                	li	a5,16
    800046f4:	06f51163          	bne	a0,a5,80004756 <dirlink+0xa2>
    if(de.inum == 0)
    800046f8:	fc045783          	lhu	a5,-64(s0)
    800046fc:	c791                	beqz	a5,80004708 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046fe:	24c1                	addiw	s1,s1,16
    80004700:	04c92783          	lw	a5,76(s2)
    80004704:	fcf4ede3          	bltu	s1,a5,800046de <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004708:	4639                	li	a2,14
    8000470a:	85d2                	mv	a1,s4
    8000470c:	fc240513          	addi	a0,s0,-62
    80004710:	ffffd097          	auipc	ra,0xffffd
    80004714:	872080e7          	jalr	-1934(ra) # 80000f82 <strncpy>
  de.inum = inum;
    80004718:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000471c:	4741                	li	a4,16
    8000471e:	86a6                	mv	a3,s1
    80004720:	fc040613          	addi	a2,s0,-64
    80004724:	4581                	li	a1,0
    80004726:	854a                	mv	a0,s2
    80004728:	00000097          	auipc	ra,0x0
    8000472c:	c3e080e7          	jalr	-962(ra) # 80004366 <writei>
    80004730:	1541                	addi	a0,a0,-16
    80004732:	00a03533          	snez	a0,a0
    80004736:	40a00533          	neg	a0,a0
}
    8000473a:	70e2                	ld	ra,56(sp)
    8000473c:	7442                	ld	s0,48(sp)
    8000473e:	74a2                	ld	s1,40(sp)
    80004740:	7902                	ld	s2,32(sp)
    80004742:	69e2                	ld	s3,24(sp)
    80004744:	6a42                	ld	s4,16(sp)
    80004746:	6121                	addi	sp,sp,64
    80004748:	8082                	ret
    iput(ip);
    8000474a:	00000097          	auipc	ra,0x0
    8000474e:	a2a080e7          	jalr	-1494(ra) # 80004174 <iput>
    return -1;
    80004752:	557d                	li	a0,-1
    80004754:	b7dd                	j	8000473a <dirlink+0x86>
      panic("dirlink read");
    80004756:	00004517          	auipc	a0,0x4
    8000475a:	f1a50513          	addi	a0,a0,-230 # 80008670 <syscalls+0x200>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	de2080e7          	jalr	-542(ra) # 80000540 <panic>

0000000080004766 <namei>:

struct inode*
namei(char *path)
{
    80004766:	1101                	addi	sp,sp,-32
    80004768:	ec06                	sd	ra,24(sp)
    8000476a:	e822                	sd	s0,16(sp)
    8000476c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000476e:	fe040613          	addi	a2,s0,-32
    80004772:	4581                	li	a1,0
    80004774:	00000097          	auipc	ra,0x0
    80004778:	dda080e7          	jalr	-550(ra) # 8000454e <namex>
}
    8000477c:	60e2                	ld	ra,24(sp)
    8000477e:	6442                	ld	s0,16(sp)
    80004780:	6105                	addi	sp,sp,32
    80004782:	8082                	ret

0000000080004784 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004784:	1141                	addi	sp,sp,-16
    80004786:	e406                	sd	ra,8(sp)
    80004788:	e022                	sd	s0,0(sp)
    8000478a:	0800                	addi	s0,sp,16
    8000478c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000478e:	4585                	li	a1,1
    80004790:	00000097          	auipc	ra,0x0
    80004794:	dbe080e7          	jalr	-578(ra) # 8000454e <namex>
}
    80004798:	60a2                	ld	ra,8(sp)
    8000479a:	6402                	ld	s0,0(sp)
    8000479c:	0141                	addi	sp,sp,16
    8000479e:	8082                	ret

00000000800047a0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800047a0:	1101                	addi	sp,sp,-32
    800047a2:	ec06                	sd	ra,24(sp)
    800047a4:	e822                	sd	s0,16(sp)
    800047a6:	e426                	sd	s1,8(sp)
    800047a8:	e04a                	sd	s2,0(sp)
    800047aa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800047ac:	0023e917          	auipc	s2,0x23e
    800047b0:	bec90913          	addi	s2,s2,-1044 # 80242398 <log>
    800047b4:	01892583          	lw	a1,24(s2)
    800047b8:	02892503          	lw	a0,40(s2)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	fe6080e7          	jalr	-26(ra) # 800037a2 <bread>
    800047c4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800047c6:	02c92683          	lw	a3,44(s2)
    800047ca:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800047cc:	02d05863          	blez	a3,800047fc <write_head+0x5c>
    800047d0:	0023e797          	auipc	a5,0x23e
    800047d4:	bf878793          	addi	a5,a5,-1032 # 802423c8 <log+0x30>
    800047d8:	05c50713          	addi	a4,a0,92
    800047dc:	36fd                	addiw	a3,a3,-1
    800047de:	02069613          	slli	a2,a3,0x20
    800047e2:	01e65693          	srli	a3,a2,0x1e
    800047e6:	0023e617          	auipc	a2,0x23e
    800047ea:	be660613          	addi	a2,a2,-1050 # 802423cc <log+0x34>
    800047ee:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800047f0:	4390                	lw	a2,0(a5)
    800047f2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047f4:	0791                	addi	a5,a5,4
    800047f6:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800047f8:	fed79ce3          	bne	a5,a3,800047f0 <write_head+0x50>
  }
  bwrite(buf);
    800047fc:	8526                	mv	a0,s1
    800047fe:	fffff097          	auipc	ra,0xfffff
    80004802:	096080e7          	jalr	150(ra) # 80003894 <bwrite>
  brelse(buf);
    80004806:	8526                	mv	a0,s1
    80004808:	fffff097          	auipc	ra,0xfffff
    8000480c:	0ca080e7          	jalr	202(ra) # 800038d2 <brelse>
}
    80004810:	60e2                	ld	ra,24(sp)
    80004812:	6442                	ld	s0,16(sp)
    80004814:	64a2                	ld	s1,8(sp)
    80004816:	6902                	ld	s2,0(sp)
    80004818:	6105                	addi	sp,sp,32
    8000481a:	8082                	ret

000000008000481c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000481c:	0023e797          	auipc	a5,0x23e
    80004820:	ba87a783          	lw	a5,-1112(a5) # 802423c4 <log+0x2c>
    80004824:	0af05d63          	blez	a5,800048de <install_trans+0xc2>
{
    80004828:	7139                	addi	sp,sp,-64
    8000482a:	fc06                	sd	ra,56(sp)
    8000482c:	f822                	sd	s0,48(sp)
    8000482e:	f426                	sd	s1,40(sp)
    80004830:	f04a                	sd	s2,32(sp)
    80004832:	ec4e                	sd	s3,24(sp)
    80004834:	e852                	sd	s4,16(sp)
    80004836:	e456                	sd	s5,8(sp)
    80004838:	e05a                	sd	s6,0(sp)
    8000483a:	0080                	addi	s0,sp,64
    8000483c:	8b2a                	mv	s6,a0
    8000483e:	0023ea97          	auipc	s5,0x23e
    80004842:	b8aa8a93          	addi	s5,s5,-1142 # 802423c8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004846:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004848:	0023e997          	auipc	s3,0x23e
    8000484c:	b5098993          	addi	s3,s3,-1200 # 80242398 <log>
    80004850:	a00d                	j	80004872 <install_trans+0x56>
    brelse(lbuf);
    80004852:	854a                	mv	a0,s2
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	07e080e7          	jalr	126(ra) # 800038d2 <brelse>
    brelse(dbuf);
    8000485c:	8526                	mv	a0,s1
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	074080e7          	jalr	116(ra) # 800038d2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004866:	2a05                	addiw	s4,s4,1
    80004868:	0a91                	addi	s5,s5,4
    8000486a:	02c9a783          	lw	a5,44(s3)
    8000486e:	04fa5e63          	bge	s4,a5,800048ca <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004872:	0189a583          	lw	a1,24(s3)
    80004876:	014585bb          	addw	a1,a1,s4
    8000487a:	2585                	addiw	a1,a1,1
    8000487c:	0289a503          	lw	a0,40(s3)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	f22080e7          	jalr	-222(ra) # 800037a2 <bread>
    80004888:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000488a:	000aa583          	lw	a1,0(s5)
    8000488e:	0289a503          	lw	a0,40(s3)
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	f10080e7          	jalr	-240(ra) # 800037a2 <bread>
    8000489a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000489c:	40000613          	li	a2,1024
    800048a0:	05890593          	addi	a1,s2,88
    800048a4:	05850513          	addi	a0,a0,88
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	62a080e7          	jalr	1578(ra) # 80000ed2 <memmove>
    bwrite(dbuf);  // write dst to disk
    800048b0:	8526                	mv	a0,s1
    800048b2:	fffff097          	auipc	ra,0xfffff
    800048b6:	fe2080e7          	jalr	-30(ra) # 80003894 <bwrite>
    if(recovering == 0)
    800048ba:	f80b1ce3          	bnez	s6,80004852 <install_trans+0x36>
      bunpin(dbuf);
    800048be:	8526                	mv	a0,s1
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	0ec080e7          	jalr	236(ra) # 800039ac <bunpin>
    800048c8:	b769                	j	80004852 <install_trans+0x36>
}
    800048ca:	70e2                	ld	ra,56(sp)
    800048cc:	7442                	ld	s0,48(sp)
    800048ce:	74a2                	ld	s1,40(sp)
    800048d0:	7902                	ld	s2,32(sp)
    800048d2:	69e2                	ld	s3,24(sp)
    800048d4:	6a42                	ld	s4,16(sp)
    800048d6:	6aa2                	ld	s5,8(sp)
    800048d8:	6b02                	ld	s6,0(sp)
    800048da:	6121                	addi	sp,sp,64
    800048dc:	8082                	ret
    800048de:	8082                	ret

00000000800048e0 <initlog>:
{
    800048e0:	7179                	addi	sp,sp,-48
    800048e2:	f406                	sd	ra,40(sp)
    800048e4:	f022                	sd	s0,32(sp)
    800048e6:	ec26                	sd	s1,24(sp)
    800048e8:	e84a                	sd	s2,16(sp)
    800048ea:	e44e                	sd	s3,8(sp)
    800048ec:	1800                	addi	s0,sp,48
    800048ee:	892a                	mv	s2,a0
    800048f0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800048f2:	0023e497          	auipc	s1,0x23e
    800048f6:	aa648493          	addi	s1,s1,-1370 # 80242398 <log>
    800048fa:	00004597          	auipc	a1,0x4
    800048fe:	d8658593          	addi	a1,a1,-634 # 80008680 <syscalls+0x210>
    80004902:	8526                	mv	a0,s1
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	3e6080e7          	jalr	998(ra) # 80000cea <initlock>
  log.start = sb->logstart;
    8000490c:	0149a583          	lw	a1,20(s3)
    80004910:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004912:	0109a783          	lw	a5,16(s3)
    80004916:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004918:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000491c:	854a                	mv	a0,s2
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	e84080e7          	jalr	-380(ra) # 800037a2 <bread>
  log.lh.n = lh->n;
    80004926:	4d34                	lw	a3,88(a0)
    80004928:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000492a:	02d05663          	blez	a3,80004956 <initlog+0x76>
    8000492e:	05c50793          	addi	a5,a0,92
    80004932:	0023e717          	auipc	a4,0x23e
    80004936:	a9670713          	addi	a4,a4,-1386 # 802423c8 <log+0x30>
    8000493a:	36fd                	addiw	a3,a3,-1
    8000493c:	02069613          	slli	a2,a3,0x20
    80004940:	01e65693          	srli	a3,a2,0x1e
    80004944:	06050613          	addi	a2,a0,96
    80004948:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000494a:	4390                	lw	a2,0(a5)
    8000494c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000494e:	0791                	addi	a5,a5,4
    80004950:	0711                	addi	a4,a4,4
    80004952:	fed79ce3          	bne	a5,a3,8000494a <initlog+0x6a>
  brelse(buf);
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	f7c080e7          	jalr	-132(ra) # 800038d2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000495e:	4505                	li	a0,1
    80004960:	00000097          	auipc	ra,0x0
    80004964:	ebc080e7          	jalr	-324(ra) # 8000481c <install_trans>
  log.lh.n = 0;
    80004968:	0023e797          	auipc	a5,0x23e
    8000496c:	a407ae23          	sw	zero,-1444(a5) # 802423c4 <log+0x2c>
  write_head(); // clear the log
    80004970:	00000097          	auipc	ra,0x0
    80004974:	e30080e7          	jalr	-464(ra) # 800047a0 <write_head>
}
    80004978:	70a2                	ld	ra,40(sp)
    8000497a:	7402                	ld	s0,32(sp)
    8000497c:	64e2                	ld	s1,24(sp)
    8000497e:	6942                	ld	s2,16(sp)
    80004980:	69a2                	ld	s3,8(sp)
    80004982:	6145                	addi	sp,sp,48
    80004984:	8082                	ret

0000000080004986 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004986:	1101                	addi	sp,sp,-32
    80004988:	ec06                	sd	ra,24(sp)
    8000498a:	e822                	sd	s0,16(sp)
    8000498c:	e426                	sd	s1,8(sp)
    8000498e:	e04a                	sd	s2,0(sp)
    80004990:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004992:	0023e517          	auipc	a0,0x23e
    80004996:	a0650513          	addi	a0,a0,-1530 # 80242398 <log>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	3e0080e7          	jalr	992(ra) # 80000d7a <acquire>
  while(1){
    if(log.committing){
    800049a2:	0023e497          	auipc	s1,0x23e
    800049a6:	9f648493          	addi	s1,s1,-1546 # 80242398 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049aa:	4979                	li	s2,30
    800049ac:	a039                	j	800049ba <begin_op+0x34>
      sleep(&log, &log.lock);
    800049ae:	85a6                	mv	a1,s1
    800049b0:	8526                	mv	a0,s1
    800049b2:	ffffe097          	auipc	ra,0xffffe
    800049b6:	99e080e7          	jalr	-1634(ra) # 80002350 <sleep>
    if(log.committing){
    800049ba:	50dc                	lw	a5,36(s1)
    800049bc:	fbed                	bnez	a5,800049ae <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049be:	5098                	lw	a4,32(s1)
    800049c0:	2705                	addiw	a4,a4,1
    800049c2:	0007069b          	sext.w	a3,a4
    800049c6:	0027179b          	slliw	a5,a4,0x2
    800049ca:	9fb9                	addw	a5,a5,a4
    800049cc:	0017979b          	slliw	a5,a5,0x1
    800049d0:	54d8                	lw	a4,44(s1)
    800049d2:	9fb9                	addw	a5,a5,a4
    800049d4:	00f95963          	bge	s2,a5,800049e6 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800049d8:	85a6                	mv	a1,s1
    800049da:	8526                	mv	a0,s1
    800049dc:	ffffe097          	auipc	ra,0xffffe
    800049e0:	974080e7          	jalr	-1676(ra) # 80002350 <sleep>
    800049e4:	bfd9                	j	800049ba <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800049e6:	0023e517          	auipc	a0,0x23e
    800049ea:	9b250513          	addi	a0,a0,-1614 # 80242398 <log>
    800049ee:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	43e080e7          	jalr	1086(ra) # 80000e2e <release>
      break;
    }
  }
}
    800049f8:	60e2                	ld	ra,24(sp)
    800049fa:	6442                	ld	s0,16(sp)
    800049fc:	64a2                	ld	s1,8(sp)
    800049fe:	6902                	ld	s2,0(sp)
    80004a00:	6105                	addi	sp,sp,32
    80004a02:	8082                	ret

0000000080004a04 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a04:	7139                	addi	sp,sp,-64
    80004a06:	fc06                	sd	ra,56(sp)
    80004a08:	f822                	sd	s0,48(sp)
    80004a0a:	f426                	sd	s1,40(sp)
    80004a0c:	f04a                	sd	s2,32(sp)
    80004a0e:	ec4e                	sd	s3,24(sp)
    80004a10:	e852                	sd	s4,16(sp)
    80004a12:	e456                	sd	s5,8(sp)
    80004a14:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a16:	0023e497          	auipc	s1,0x23e
    80004a1a:	98248493          	addi	s1,s1,-1662 # 80242398 <log>
    80004a1e:	8526                	mv	a0,s1
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	35a080e7          	jalr	858(ra) # 80000d7a <acquire>
  log.outstanding -= 1;
    80004a28:	509c                	lw	a5,32(s1)
    80004a2a:	37fd                	addiw	a5,a5,-1
    80004a2c:	0007891b          	sext.w	s2,a5
    80004a30:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a32:	50dc                	lw	a5,36(s1)
    80004a34:	e7b9                	bnez	a5,80004a82 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a36:	04091e63          	bnez	s2,80004a92 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004a3a:	0023e497          	auipc	s1,0x23e
    80004a3e:	95e48493          	addi	s1,s1,-1698 # 80242398 <log>
    80004a42:	4785                	li	a5,1
    80004a44:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	3e6080e7          	jalr	998(ra) # 80000e2e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a50:	54dc                	lw	a5,44(s1)
    80004a52:	06f04763          	bgtz	a5,80004ac0 <end_op+0xbc>
    acquire(&log.lock);
    80004a56:	0023e497          	auipc	s1,0x23e
    80004a5a:	94248493          	addi	s1,s1,-1726 # 80242398 <log>
    80004a5e:	8526                	mv	a0,s1
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	31a080e7          	jalr	794(ra) # 80000d7a <acquire>
    log.committing = 0;
    80004a68:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a6c:	8526                	mv	a0,s1
    80004a6e:	ffffe097          	auipc	ra,0xffffe
    80004a72:	946080e7          	jalr	-1722(ra) # 800023b4 <wakeup>
    release(&log.lock);
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	3b6080e7          	jalr	950(ra) # 80000e2e <release>
}
    80004a80:	a03d                	j	80004aae <end_op+0xaa>
    panic("log.committing");
    80004a82:	00004517          	auipc	a0,0x4
    80004a86:	c0650513          	addi	a0,a0,-1018 # 80008688 <syscalls+0x218>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	ab6080e7          	jalr	-1354(ra) # 80000540 <panic>
    wakeup(&log);
    80004a92:	0023e497          	auipc	s1,0x23e
    80004a96:	90648493          	addi	s1,s1,-1786 # 80242398 <log>
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffe097          	auipc	ra,0xffffe
    80004aa0:	918080e7          	jalr	-1768(ra) # 800023b4 <wakeup>
  release(&log.lock);
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	388080e7          	jalr	904(ra) # 80000e2e <release>
}
    80004aae:	70e2                	ld	ra,56(sp)
    80004ab0:	7442                	ld	s0,48(sp)
    80004ab2:	74a2                	ld	s1,40(sp)
    80004ab4:	7902                	ld	s2,32(sp)
    80004ab6:	69e2                	ld	s3,24(sp)
    80004ab8:	6a42                	ld	s4,16(sp)
    80004aba:	6aa2                	ld	s5,8(sp)
    80004abc:	6121                	addi	sp,sp,64
    80004abe:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ac0:	0023ea97          	auipc	s5,0x23e
    80004ac4:	908a8a93          	addi	s5,s5,-1784 # 802423c8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ac8:	0023ea17          	auipc	s4,0x23e
    80004acc:	8d0a0a13          	addi	s4,s4,-1840 # 80242398 <log>
    80004ad0:	018a2583          	lw	a1,24(s4)
    80004ad4:	012585bb          	addw	a1,a1,s2
    80004ad8:	2585                	addiw	a1,a1,1
    80004ada:	028a2503          	lw	a0,40(s4)
    80004ade:	fffff097          	auipc	ra,0xfffff
    80004ae2:	cc4080e7          	jalr	-828(ra) # 800037a2 <bread>
    80004ae6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004ae8:	000aa583          	lw	a1,0(s5)
    80004aec:	028a2503          	lw	a0,40(s4)
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	cb2080e7          	jalr	-846(ra) # 800037a2 <bread>
    80004af8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004afa:	40000613          	li	a2,1024
    80004afe:	05850593          	addi	a1,a0,88
    80004b02:	05848513          	addi	a0,s1,88
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	3cc080e7          	jalr	972(ra) # 80000ed2 <memmove>
    bwrite(to);  // write the log
    80004b0e:	8526                	mv	a0,s1
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	d84080e7          	jalr	-636(ra) # 80003894 <bwrite>
    brelse(from);
    80004b18:	854e                	mv	a0,s3
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	db8080e7          	jalr	-584(ra) # 800038d2 <brelse>
    brelse(to);
    80004b22:	8526                	mv	a0,s1
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	dae080e7          	jalr	-594(ra) # 800038d2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b2c:	2905                	addiw	s2,s2,1
    80004b2e:	0a91                	addi	s5,s5,4
    80004b30:	02ca2783          	lw	a5,44(s4)
    80004b34:	f8f94ee3          	blt	s2,a5,80004ad0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b38:	00000097          	auipc	ra,0x0
    80004b3c:	c68080e7          	jalr	-920(ra) # 800047a0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004b40:	4501                	li	a0,0
    80004b42:	00000097          	auipc	ra,0x0
    80004b46:	cda080e7          	jalr	-806(ra) # 8000481c <install_trans>
    log.lh.n = 0;
    80004b4a:	0023e797          	auipc	a5,0x23e
    80004b4e:	8607ad23          	sw	zero,-1926(a5) # 802423c4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b52:	00000097          	auipc	ra,0x0
    80004b56:	c4e080e7          	jalr	-946(ra) # 800047a0 <write_head>
    80004b5a:	bdf5                	j	80004a56 <end_op+0x52>

0000000080004b5c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b5c:	1101                	addi	sp,sp,-32
    80004b5e:	ec06                	sd	ra,24(sp)
    80004b60:	e822                	sd	s0,16(sp)
    80004b62:	e426                	sd	s1,8(sp)
    80004b64:	e04a                	sd	s2,0(sp)
    80004b66:	1000                	addi	s0,sp,32
    80004b68:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b6a:	0023e917          	auipc	s2,0x23e
    80004b6e:	82e90913          	addi	s2,s2,-2002 # 80242398 <log>
    80004b72:	854a                	mv	a0,s2
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	206080e7          	jalr	518(ra) # 80000d7a <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b7c:	02c92603          	lw	a2,44(s2)
    80004b80:	47f5                	li	a5,29
    80004b82:	06c7c563          	blt	a5,a2,80004bec <log_write+0x90>
    80004b86:	0023e797          	auipc	a5,0x23e
    80004b8a:	82e7a783          	lw	a5,-2002(a5) # 802423b4 <log+0x1c>
    80004b8e:	37fd                	addiw	a5,a5,-1
    80004b90:	04f65e63          	bge	a2,a5,80004bec <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b94:	0023e797          	auipc	a5,0x23e
    80004b98:	8247a783          	lw	a5,-2012(a5) # 802423b8 <log+0x20>
    80004b9c:	06f05063          	blez	a5,80004bfc <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ba0:	4781                	li	a5,0
    80004ba2:	06c05563          	blez	a2,80004c0c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ba6:	44cc                	lw	a1,12(s1)
    80004ba8:	0023e717          	auipc	a4,0x23e
    80004bac:	82070713          	addi	a4,a4,-2016 # 802423c8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004bb0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004bb2:	4314                	lw	a3,0(a4)
    80004bb4:	04b68c63          	beq	a3,a1,80004c0c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004bb8:	2785                	addiw	a5,a5,1
    80004bba:	0711                	addi	a4,a4,4
    80004bbc:	fef61be3          	bne	a2,a5,80004bb2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004bc0:	0621                	addi	a2,a2,8
    80004bc2:	060a                	slli	a2,a2,0x2
    80004bc4:	0023d797          	auipc	a5,0x23d
    80004bc8:	7d478793          	addi	a5,a5,2004 # 80242398 <log>
    80004bcc:	97b2                	add	a5,a5,a2
    80004bce:	44d8                	lw	a4,12(s1)
    80004bd0:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	fffff097          	auipc	ra,0xfffff
    80004bd8:	d9c080e7          	jalr	-612(ra) # 80003970 <bpin>
    log.lh.n++;
    80004bdc:	0023d717          	auipc	a4,0x23d
    80004be0:	7bc70713          	addi	a4,a4,1980 # 80242398 <log>
    80004be4:	575c                	lw	a5,44(a4)
    80004be6:	2785                	addiw	a5,a5,1
    80004be8:	d75c                	sw	a5,44(a4)
    80004bea:	a82d                	j	80004c24 <log_write+0xc8>
    panic("too big a transaction");
    80004bec:	00004517          	auipc	a0,0x4
    80004bf0:	aac50513          	addi	a0,a0,-1364 # 80008698 <syscalls+0x228>
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	94c080e7          	jalr	-1716(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004bfc:	00004517          	auipc	a0,0x4
    80004c00:	ab450513          	addi	a0,a0,-1356 # 800086b0 <syscalls+0x240>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	93c080e7          	jalr	-1732(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004c0c:	00878693          	addi	a3,a5,8
    80004c10:	068a                	slli	a3,a3,0x2
    80004c12:	0023d717          	auipc	a4,0x23d
    80004c16:	78670713          	addi	a4,a4,1926 # 80242398 <log>
    80004c1a:	9736                	add	a4,a4,a3
    80004c1c:	44d4                	lw	a3,12(s1)
    80004c1e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c20:	faf609e3          	beq	a2,a5,80004bd2 <log_write+0x76>
  }
  release(&log.lock);
    80004c24:	0023d517          	auipc	a0,0x23d
    80004c28:	77450513          	addi	a0,a0,1908 # 80242398 <log>
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	202080e7          	jalr	514(ra) # 80000e2e <release>
}
    80004c34:	60e2                	ld	ra,24(sp)
    80004c36:	6442                	ld	s0,16(sp)
    80004c38:	64a2                	ld	s1,8(sp)
    80004c3a:	6902                	ld	s2,0(sp)
    80004c3c:	6105                	addi	sp,sp,32
    80004c3e:	8082                	ret

0000000080004c40 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c40:	1101                	addi	sp,sp,-32
    80004c42:	ec06                	sd	ra,24(sp)
    80004c44:	e822                	sd	s0,16(sp)
    80004c46:	e426                	sd	s1,8(sp)
    80004c48:	e04a                	sd	s2,0(sp)
    80004c4a:	1000                	addi	s0,sp,32
    80004c4c:	84aa                	mv	s1,a0
    80004c4e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c50:	00004597          	auipc	a1,0x4
    80004c54:	a8058593          	addi	a1,a1,-1408 # 800086d0 <syscalls+0x260>
    80004c58:	0521                	addi	a0,a0,8
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	090080e7          	jalr	144(ra) # 80000cea <initlock>
  lk->name = name;
    80004c62:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c66:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c6a:	0204a423          	sw	zero,40(s1)
}
    80004c6e:	60e2                	ld	ra,24(sp)
    80004c70:	6442                	ld	s0,16(sp)
    80004c72:	64a2                	ld	s1,8(sp)
    80004c74:	6902                	ld	s2,0(sp)
    80004c76:	6105                	addi	sp,sp,32
    80004c78:	8082                	ret

0000000080004c7a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c7a:	1101                	addi	sp,sp,-32
    80004c7c:	ec06                	sd	ra,24(sp)
    80004c7e:	e822                	sd	s0,16(sp)
    80004c80:	e426                	sd	s1,8(sp)
    80004c82:	e04a                	sd	s2,0(sp)
    80004c84:	1000                	addi	s0,sp,32
    80004c86:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c88:	00850913          	addi	s2,a0,8
    80004c8c:	854a                	mv	a0,s2
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	0ec080e7          	jalr	236(ra) # 80000d7a <acquire>
  while (lk->locked) {
    80004c96:	409c                	lw	a5,0(s1)
    80004c98:	cb89                	beqz	a5,80004caa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c9a:	85ca                	mv	a1,s2
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	6b2080e7          	jalr	1714(ra) # 80002350 <sleep>
  while (lk->locked) {
    80004ca6:	409c                	lw	a5,0(s1)
    80004ca8:	fbed                	bnez	a5,80004c9a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004caa:	4785                	li	a5,1
    80004cac:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	ee4080e7          	jalr	-284(ra) # 80001b92 <myproc>
    80004cb6:	591c                	lw	a5,48(a0)
    80004cb8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004cba:	854a                	mv	a0,s2
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	172080e7          	jalr	370(ra) # 80000e2e <release>
}
    80004cc4:	60e2                	ld	ra,24(sp)
    80004cc6:	6442                	ld	s0,16(sp)
    80004cc8:	64a2                	ld	s1,8(sp)
    80004cca:	6902                	ld	s2,0(sp)
    80004ccc:	6105                	addi	sp,sp,32
    80004cce:	8082                	ret

0000000080004cd0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004cd0:	1101                	addi	sp,sp,-32
    80004cd2:	ec06                	sd	ra,24(sp)
    80004cd4:	e822                	sd	s0,16(sp)
    80004cd6:	e426                	sd	s1,8(sp)
    80004cd8:	e04a                	sd	s2,0(sp)
    80004cda:	1000                	addi	s0,sp,32
    80004cdc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cde:	00850913          	addi	s2,a0,8
    80004ce2:	854a                	mv	a0,s2
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	096080e7          	jalr	150(ra) # 80000d7a <acquire>
  lk->locked = 0;
    80004cec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004cf0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	6be080e7          	jalr	1726(ra) # 800023b4 <wakeup>
  release(&lk->lk);
    80004cfe:	854a                	mv	a0,s2
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	12e080e7          	jalr	302(ra) # 80000e2e <release>
}
    80004d08:	60e2                	ld	ra,24(sp)
    80004d0a:	6442                	ld	s0,16(sp)
    80004d0c:	64a2                	ld	s1,8(sp)
    80004d0e:	6902                	ld	s2,0(sp)
    80004d10:	6105                	addi	sp,sp,32
    80004d12:	8082                	ret

0000000080004d14 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d14:	7179                	addi	sp,sp,-48
    80004d16:	f406                	sd	ra,40(sp)
    80004d18:	f022                	sd	s0,32(sp)
    80004d1a:	ec26                	sd	s1,24(sp)
    80004d1c:	e84a                	sd	s2,16(sp)
    80004d1e:	e44e                	sd	s3,8(sp)
    80004d20:	1800                	addi	s0,sp,48
    80004d22:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d24:	00850913          	addi	s2,a0,8
    80004d28:	854a                	mv	a0,s2
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	050080e7          	jalr	80(ra) # 80000d7a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d32:	409c                	lw	a5,0(s1)
    80004d34:	ef99                	bnez	a5,80004d52 <holdingsleep+0x3e>
    80004d36:	4481                	li	s1,0
  release(&lk->lk);
    80004d38:	854a                	mv	a0,s2
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	0f4080e7          	jalr	244(ra) # 80000e2e <release>
  return r;
}
    80004d42:	8526                	mv	a0,s1
    80004d44:	70a2                	ld	ra,40(sp)
    80004d46:	7402                	ld	s0,32(sp)
    80004d48:	64e2                	ld	s1,24(sp)
    80004d4a:	6942                	ld	s2,16(sp)
    80004d4c:	69a2                	ld	s3,8(sp)
    80004d4e:	6145                	addi	sp,sp,48
    80004d50:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d52:	0284a983          	lw	s3,40(s1)
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	e3c080e7          	jalr	-452(ra) # 80001b92 <myproc>
    80004d5e:	5904                	lw	s1,48(a0)
    80004d60:	413484b3          	sub	s1,s1,s3
    80004d64:	0014b493          	seqz	s1,s1
    80004d68:	bfc1                	j	80004d38 <holdingsleep+0x24>

0000000080004d6a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d6a:	1141                	addi	sp,sp,-16
    80004d6c:	e406                	sd	ra,8(sp)
    80004d6e:	e022                	sd	s0,0(sp)
    80004d70:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d72:	00004597          	auipc	a1,0x4
    80004d76:	96e58593          	addi	a1,a1,-1682 # 800086e0 <syscalls+0x270>
    80004d7a:	0023d517          	auipc	a0,0x23d
    80004d7e:	76650513          	addi	a0,a0,1894 # 802424e0 <ftable>
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	f68080e7          	jalr	-152(ra) # 80000cea <initlock>
}
    80004d8a:	60a2                	ld	ra,8(sp)
    80004d8c:	6402                	ld	s0,0(sp)
    80004d8e:	0141                	addi	sp,sp,16
    80004d90:	8082                	ret

0000000080004d92 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d92:	1101                	addi	sp,sp,-32
    80004d94:	ec06                	sd	ra,24(sp)
    80004d96:	e822                	sd	s0,16(sp)
    80004d98:	e426                	sd	s1,8(sp)
    80004d9a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d9c:	0023d517          	auipc	a0,0x23d
    80004da0:	74450513          	addi	a0,a0,1860 # 802424e0 <ftable>
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	fd6080e7          	jalr	-42(ra) # 80000d7a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dac:	0023d497          	auipc	s1,0x23d
    80004db0:	74c48493          	addi	s1,s1,1868 # 802424f8 <ftable+0x18>
    80004db4:	0023e717          	auipc	a4,0x23e
    80004db8:	6e470713          	addi	a4,a4,1764 # 80243498 <disk>
    if(f->ref == 0){
    80004dbc:	40dc                	lw	a5,4(s1)
    80004dbe:	cf99                	beqz	a5,80004ddc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dc0:	02848493          	addi	s1,s1,40
    80004dc4:	fee49ce3          	bne	s1,a4,80004dbc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004dc8:	0023d517          	auipc	a0,0x23d
    80004dcc:	71850513          	addi	a0,a0,1816 # 802424e0 <ftable>
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	05e080e7          	jalr	94(ra) # 80000e2e <release>
  return 0;
    80004dd8:	4481                	li	s1,0
    80004dda:	a819                	j	80004df0 <filealloc+0x5e>
      f->ref = 1;
    80004ddc:	4785                	li	a5,1
    80004dde:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004de0:	0023d517          	auipc	a0,0x23d
    80004de4:	70050513          	addi	a0,a0,1792 # 802424e0 <ftable>
    80004de8:	ffffc097          	auipc	ra,0xffffc
    80004dec:	046080e7          	jalr	70(ra) # 80000e2e <release>
}
    80004df0:	8526                	mv	a0,s1
    80004df2:	60e2                	ld	ra,24(sp)
    80004df4:	6442                	ld	s0,16(sp)
    80004df6:	64a2                	ld	s1,8(sp)
    80004df8:	6105                	addi	sp,sp,32
    80004dfa:	8082                	ret

0000000080004dfc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004dfc:	1101                	addi	sp,sp,-32
    80004dfe:	ec06                	sd	ra,24(sp)
    80004e00:	e822                	sd	s0,16(sp)
    80004e02:	e426                	sd	s1,8(sp)
    80004e04:	1000                	addi	s0,sp,32
    80004e06:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e08:	0023d517          	auipc	a0,0x23d
    80004e0c:	6d850513          	addi	a0,a0,1752 # 802424e0 <ftable>
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	f6a080e7          	jalr	-150(ra) # 80000d7a <acquire>
  if(f->ref < 1)
    80004e18:	40dc                	lw	a5,4(s1)
    80004e1a:	02f05263          	blez	a5,80004e3e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e1e:	2785                	addiw	a5,a5,1
    80004e20:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e22:	0023d517          	auipc	a0,0x23d
    80004e26:	6be50513          	addi	a0,a0,1726 # 802424e0 <ftable>
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	004080e7          	jalr	4(ra) # 80000e2e <release>
  return f;
}
    80004e32:	8526                	mv	a0,s1
    80004e34:	60e2                	ld	ra,24(sp)
    80004e36:	6442                	ld	s0,16(sp)
    80004e38:	64a2                	ld	s1,8(sp)
    80004e3a:	6105                	addi	sp,sp,32
    80004e3c:	8082                	ret
    panic("filedup");
    80004e3e:	00004517          	auipc	a0,0x4
    80004e42:	8aa50513          	addi	a0,a0,-1878 # 800086e8 <syscalls+0x278>
    80004e46:	ffffb097          	auipc	ra,0xffffb
    80004e4a:	6fa080e7          	jalr	1786(ra) # 80000540 <panic>

0000000080004e4e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e4e:	7139                	addi	sp,sp,-64
    80004e50:	fc06                	sd	ra,56(sp)
    80004e52:	f822                	sd	s0,48(sp)
    80004e54:	f426                	sd	s1,40(sp)
    80004e56:	f04a                	sd	s2,32(sp)
    80004e58:	ec4e                	sd	s3,24(sp)
    80004e5a:	e852                	sd	s4,16(sp)
    80004e5c:	e456                	sd	s5,8(sp)
    80004e5e:	0080                	addi	s0,sp,64
    80004e60:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e62:	0023d517          	auipc	a0,0x23d
    80004e66:	67e50513          	addi	a0,a0,1662 # 802424e0 <ftable>
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	f10080e7          	jalr	-240(ra) # 80000d7a <acquire>
  if(f->ref < 1)
    80004e72:	40dc                	lw	a5,4(s1)
    80004e74:	06f05163          	blez	a5,80004ed6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e78:	37fd                	addiw	a5,a5,-1
    80004e7a:	0007871b          	sext.w	a4,a5
    80004e7e:	c0dc                	sw	a5,4(s1)
    80004e80:	06e04363          	bgtz	a4,80004ee6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e84:	0004a903          	lw	s2,0(s1)
    80004e88:	0094ca83          	lbu	s5,9(s1)
    80004e8c:	0104ba03          	ld	s4,16(s1)
    80004e90:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004e94:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e98:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e9c:	0023d517          	auipc	a0,0x23d
    80004ea0:	64450513          	addi	a0,a0,1604 # 802424e0 <ftable>
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	f8a080e7          	jalr	-118(ra) # 80000e2e <release>

  if(ff.type == FD_PIPE){
    80004eac:	4785                	li	a5,1
    80004eae:	04f90d63          	beq	s2,a5,80004f08 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004eb2:	3979                	addiw	s2,s2,-2
    80004eb4:	4785                	li	a5,1
    80004eb6:	0527e063          	bltu	a5,s2,80004ef6 <fileclose+0xa8>
    begin_op();
    80004eba:	00000097          	auipc	ra,0x0
    80004ebe:	acc080e7          	jalr	-1332(ra) # 80004986 <begin_op>
    iput(ff.ip);
    80004ec2:	854e                	mv	a0,s3
    80004ec4:	fffff097          	auipc	ra,0xfffff
    80004ec8:	2b0080e7          	jalr	688(ra) # 80004174 <iput>
    end_op();
    80004ecc:	00000097          	auipc	ra,0x0
    80004ed0:	b38080e7          	jalr	-1224(ra) # 80004a04 <end_op>
    80004ed4:	a00d                	j	80004ef6 <fileclose+0xa8>
    panic("fileclose");
    80004ed6:	00004517          	auipc	a0,0x4
    80004eda:	81a50513          	addi	a0,a0,-2022 # 800086f0 <syscalls+0x280>
    80004ede:	ffffb097          	auipc	ra,0xffffb
    80004ee2:	662080e7          	jalr	1634(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004ee6:	0023d517          	auipc	a0,0x23d
    80004eea:	5fa50513          	addi	a0,a0,1530 # 802424e0 <ftable>
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	f40080e7          	jalr	-192(ra) # 80000e2e <release>
  }
}
    80004ef6:	70e2                	ld	ra,56(sp)
    80004ef8:	7442                	ld	s0,48(sp)
    80004efa:	74a2                	ld	s1,40(sp)
    80004efc:	7902                	ld	s2,32(sp)
    80004efe:	69e2                	ld	s3,24(sp)
    80004f00:	6a42                	ld	s4,16(sp)
    80004f02:	6aa2                	ld	s5,8(sp)
    80004f04:	6121                	addi	sp,sp,64
    80004f06:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f08:	85d6                	mv	a1,s5
    80004f0a:	8552                	mv	a0,s4
    80004f0c:	00000097          	auipc	ra,0x0
    80004f10:	34c080e7          	jalr	844(ra) # 80005258 <pipeclose>
    80004f14:	b7cd                	j	80004ef6 <fileclose+0xa8>

0000000080004f16 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f16:	715d                	addi	sp,sp,-80
    80004f18:	e486                	sd	ra,72(sp)
    80004f1a:	e0a2                	sd	s0,64(sp)
    80004f1c:	fc26                	sd	s1,56(sp)
    80004f1e:	f84a                	sd	s2,48(sp)
    80004f20:	f44e                	sd	s3,40(sp)
    80004f22:	0880                	addi	s0,sp,80
    80004f24:	84aa                	mv	s1,a0
    80004f26:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f28:	ffffd097          	auipc	ra,0xffffd
    80004f2c:	c6a080e7          	jalr	-918(ra) # 80001b92 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f30:	409c                	lw	a5,0(s1)
    80004f32:	37f9                	addiw	a5,a5,-2
    80004f34:	4705                	li	a4,1
    80004f36:	04f76763          	bltu	a4,a5,80004f84 <filestat+0x6e>
    80004f3a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f3c:	6c88                	ld	a0,24(s1)
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	07c080e7          	jalr	124(ra) # 80003fba <ilock>
    stati(f->ip, &st);
    80004f46:	fb840593          	addi	a1,s0,-72
    80004f4a:	6c88                	ld	a0,24(s1)
    80004f4c:	fffff097          	auipc	ra,0xfffff
    80004f50:	2f8080e7          	jalr	760(ra) # 80004244 <stati>
    iunlock(f->ip);
    80004f54:	6c88                	ld	a0,24(s1)
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	126080e7          	jalr	294(ra) # 8000407c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f5e:	46e1                	li	a3,24
    80004f60:	fb840613          	addi	a2,s0,-72
    80004f64:	85ce                	mv	a1,s3
    80004f66:	05093503          	ld	a0,80(s2)
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	8b0080e7          	jalr	-1872(ra) # 8000181a <copyout>
    80004f72:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f76:	60a6                	ld	ra,72(sp)
    80004f78:	6406                	ld	s0,64(sp)
    80004f7a:	74e2                	ld	s1,56(sp)
    80004f7c:	7942                	ld	s2,48(sp)
    80004f7e:	79a2                	ld	s3,40(sp)
    80004f80:	6161                	addi	sp,sp,80
    80004f82:	8082                	ret
  return -1;
    80004f84:	557d                	li	a0,-1
    80004f86:	bfc5                	j	80004f76 <filestat+0x60>

0000000080004f88 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f88:	7179                	addi	sp,sp,-48
    80004f8a:	f406                	sd	ra,40(sp)
    80004f8c:	f022                	sd	s0,32(sp)
    80004f8e:	ec26                	sd	s1,24(sp)
    80004f90:	e84a                	sd	s2,16(sp)
    80004f92:	e44e                	sd	s3,8(sp)
    80004f94:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f96:	00854783          	lbu	a5,8(a0)
    80004f9a:	c3d5                	beqz	a5,8000503e <fileread+0xb6>
    80004f9c:	84aa                	mv	s1,a0
    80004f9e:	89ae                	mv	s3,a1
    80004fa0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fa2:	411c                	lw	a5,0(a0)
    80004fa4:	4705                	li	a4,1
    80004fa6:	04e78963          	beq	a5,a4,80004ff8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004faa:	470d                	li	a4,3
    80004fac:	04e78d63          	beq	a5,a4,80005006 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fb0:	4709                	li	a4,2
    80004fb2:	06e79e63          	bne	a5,a4,8000502e <fileread+0xa6>
    ilock(f->ip);
    80004fb6:	6d08                	ld	a0,24(a0)
    80004fb8:	fffff097          	auipc	ra,0xfffff
    80004fbc:	002080e7          	jalr	2(ra) # 80003fba <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004fc0:	874a                	mv	a4,s2
    80004fc2:	5094                	lw	a3,32(s1)
    80004fc4:	864e                	mv	a2,s3
    80004fc6:	4585                	li	a1,1
    80004fc8:	6c88                	ld	a0,24(s1)
    80004fca:	fffff097          	auipc	ra,0xfffff
    80004fce:	2a4080e7          	jalr	676(ra) # 8000426e <readi>
    80004fd2:	892a                	mv	s2,a0
    80004fd4:	00a05563          	blez	a0,80004fde <fileread+0x56>
      f->off += r;
    80004fd8:	509c                	lw	a5,32(s1)
    80004fda:	9fa9                	addw	a5,a5,a0
    80004fdc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004fde:	6c88                	ld	a0,24(s1)
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	09c080e7          	jalr	156(ra) # 8000407c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004fe8:	854a                	mv	a0,s2
    80004fea:	70a2                	ld	ra,40(sp)
    80004fec:	7402                	ld	s0,32(sp)
    80004fee:	64e2                	ld	s1,24(sp)
    80004ff0:	6942                	ld	s2,16(sp)
    80004ff2:	69a2                	ld	s3,8(sp)
    80004ff4:	6145                	addi	sp,sp,48
    80004ff6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ff8:	6908                	ld	a0,16(a0)
    80004ffa:	00000097          	auipc	ra,0x0
    80004ffe:	3c6080e7          	jalr	966(ra) # 800053c0 <piperead>
    80005002:	892a                	mv	s2,a0
    80005004:	b7d5                	j	80004fe8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005006:	02451783          	lh	a5,36(a0)
    8000500a:	03079693          	slli	a3,a5,0x30
    8000500e:	92c1                	srli	a3,a3,0x30
    80005010:	4725                	li	a4,9
    80005012:	02d76863          	bltu	a4,a3,80005042 <fileread+0xba>
    80005016:	0792                	slli	a5,a5,0x4
    80005018:	0023d717          	auipc	a4,0x23d
    8000501c:	42870713          	addi	a4,a4,1064 # 80242440 <devsw>
    80005020:	97ba                	add	a5,a5,a4
    80005022:	639c                	ld	a5,0(a5)
    80005024:	c38d                	beqz	a5,80005046 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005026:	4505                	li	a0,1
    80005028:	9782                	jalr	a5
    8000502a:	892a                	mv	s2,a0
    8000502c:	bf75                	j	80004fe8 <fileread+0x60>
    panic("fileread");
    8000502e:	00003517          	auipc	a0,0x3
    80005032:	6d250513          	addi	a0,a0,1746 # 80008700 <syscalls+0x290>
    80005036:	ffffb097          	auipc	ra,0xffffb
    8000503a:	50a080e7          	jalr	1290(ra) # 80000540 <panic>
    return -1;
    8000503e:	597d                	li	s2,-1
    80005040:	b765                	j	80004fe8 <fileread+0x60>
      return -1;
    80005042:	597d                	li	s2,-1
    80005044:	b755                	j	80004fe8 <fileread+0x60>
    80005046:	597d                	li	s2,-1
    80005048:	b745                	j	80004fe8 <fileread+0x60>

000000008000504a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000504a:	715d                	addi	sp,sp,-80
    8000504c:	e486                	sd	ra,72(sp)
    8000504e:	e0a2                	sd	s0,64(sp)
    80005050:	fc26                	sd	s1,56(sp)
    80005052:	f84a                	sd	s2,48(sp)
    80005054:	f44e                	sd	s3,40(sp)
    80005056:	f052                	sd	s4,32(sp)
    80005058:	ec56                	sd	s5,24(sp)
    8000505a:	e85a                	sd	s6,16(sp)
    8000505c:	e45e                	sd	s7,8(sp)
    8000505e:	e062                	sd	s8,0(sp)
    80005060:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005062:	00954783          	lbu	a5,9(a0)
    80005066:	10078663          	beqz	a5,80005172 <filewrite+0x128>
    8000506a:	892a                	mv	s2,a0
    8000506c:	8b2e                	mv	s6,a1
    8000506e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005070:	411c                	lw	a5,0(a0)
    80005072:	4705                	li	a4,1
    80005074:	02e78263          	beq	a5,a4,80005098 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005078:	470d                	li	a4,3
    8000507a:	02e78663          	beq	a5,a4,800050a6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000507e:	4709                	li	a4,2
    80005080:	0ee79163          	bne	a5,a4,80005162 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005084:	0ac05d63          	blez	a2,8000513e <filewrite+0xf4>
    int i = 0;
    80005088:	4981                	li	s3,0
    8000508a:	6b85                	lui	s7,0x1
    8000508c:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005090:	6c05                	lui	s8,0x1
    80005092:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005096:	a861                	j	8000512e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005098:	6908                	ld	a0,16(a0)
    8000509a:	00000097          	auipc	ra,0x0
    8000509e:	22e080e7          	jalr	558(ra) # 800052c8 <pipewrite>
    800050a2:	8a2a                	mv	s4,a0
    800050a4:	a045                	j	80005144 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800050a6:	02451783          	lh	a5,36(a0)
    800050aa:	03079693          	slli	a3,a5,0x30
    800050ae:	92c1                	srli	a3,a3,0x30
    800050b0:	4725                	li	a4,9
    800050b2:	0cd76263          	bltu	a4,a3,80005176 <filewrite+0x12c>
    800050b6:	0792                	slli	a5,a5,0x4
    800050b8:	0023d717          	auipc	a4,0x23d
    800050bc:	38870713          	addi	a4,a4,904 # 80242440 <devsw>
    800050c0:	97ba                	add	a5,a5,a4
    800050c2:	679c                	ld	a5,8(a5)
    800050c4:	cbdd                	beqz	a5,8000517a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800050c6:	4505                	li	a0,1
    800050c8:	9782                	jalr	a5
    800050ca:	8a2a                	mv	s4,a0
    800050cc:	a8a5                	j	80005144 <filewrite+0xfa>
    800050ce:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800050d2:	00000097          	auipc	ra,0x0
    800050d6:	8b4080e7          	jalr	-1868(ra) # 80004986 <begin_op>
      ilock(f->ip);
    800050da:	01893503          	ld	a0,24(s2)
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	edc080e7          	jalr	-292(ra) # 80003fba <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800050e6:	8756                	mv	a4,s5
    800050e8:	02092683          	lw	a3,32(s2)
    800050ec:	01698633          	add	a2,s3,s6
    800050f0:	4585                	li	a1,1
    800050f2:	01893503          	ld	a0,24(s2)
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	270080e7          	jalr	624(ra) # 80004366 <writei>
    800050fe:	84aa                	mv	s1,a0
    80005100:	00a05763          	blez	a0,8000510e <filewrite+0xc4>
        f->off += r;
    80005104:	02092783          	lw	a5,32(s2)
    80005108:	9fa9                	addw	a5,a5,a0
    8000510a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000510e:	01893503          	ld	a0,24(s2)
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	f6a080e7          	jalr	-150(ra) # 8000407c <iunlock>
      end_op();
    8000511a:	00000097          	auipc	ra,0x0
    8000511e:	8ea080e7          	jalr	-1814(ra) # 80004a04 <end_op>

      if(r != n1){
    80005122:	009a9f63          	bne	s5,s1,80005140 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005126:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000512a:	0149db63          	bge	s3,s4,80005140 <filewrite+0xf6>
      int n1 = n - i;
    8000512e:	413a04bb          	subw	s1,s4,s3
    80005132:	0004879b          	sext.w	a5,s1
    80005136:	f8fbdce3          	bge	s7,a5,800050ce <filewrite+0x84>
    8000513a:	84e2                	mv	s1,s8
    8000513c:	bf49                	j	800050ce <filewrite+0x84>
    int i = 0;
    8000513e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005140:	013a1f63          	bne	s4,s3,8000515e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005144:	8552                	mv	a0,s4
    80005146:	60a6                	ld	ra,72(sp)
    80005148:	6406                	ld	s0,64(sp)
    8000514a:	74e2                	ld	s1,56(sp)
    8000514c:	7942                	ld	s2,48(sp)
    8000514e:	79a2                	ld	s3,40(sp)
    80005150:	7a02                	ld	s4,32(sp)
    80005152:	6ae2                	ld	s5,24(sp)
    80005154:	6b42                	ld	s6,16(sp)
    80005156:	6ba2                	ld	s7,8(sp)
    80005158:	6c02                	ld	s8,0(sp)
    8000515a:	6161                	addi	sp,sp,80
    8000515c:	8082                	ret
    ret = (i == n ? n : -1);
    8000515e:	5a7d                	li	s4,-1
    80005160:	b7d5                	j	80005144 <filewrite+0xfa>
    panic("filewrite");
    80005162:	00003517          	auipc	a0,0x3
    80005166:	5ae50513          	addi	a0,a0,1454 # 80008710 <syscalls+0x2a0>
    8000516a:	ffffb097          	auipc	ra,0xffffb
    8000516e:	3d6080e7          	jalr	982(ra) # 80000540 <panic>
    return -1;
    80005172:	5a7d                	li	s4,-1
    80005174:	bfc1                	j	80005144 <filewrite+0xfa>
      return -1;
    80005176:	5a7d                	li	s4,-1
    80005178:	b7f1                	j	80005144 <filewrite+0xfa>
    8000517a:	5a7d                	li	s4,-1
    8000517c:	b7e1                	j	80005144 <filewrite+0xfa>

000000008000517e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000517e:	7179                	addi	sp,sp,-48
    80005180:	f406                	sd	ra,40(sp)
    80005182:	f022                	sd	s0,32(sp)
    80005184:	ec26                	sd	s1,24(sp)
    80005186:	e84a                	sd	s2,16(sp)
    80005188:	e44e                	sd	s3,8(sp)
    8000518a:	e052                	sd	s4,0(sp)
    8000518c:	1800                	addi	s0,sp,48
    8000518e:	84aa                	mv	s1,a0
    80005190:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005192:	0005b023          	sd	zero,0(a1)
    80005196:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000519a:	00000097          	auipc	ra,0x0
    8000519e:	bf8080e7          	jalr	-1032(ra) # 80004d92 <filealloc>
    800051a2:	e088                	sd	a0,0(s1)
    800051a4:	c551                	beqz	a0,80005230 <pipealloc+0xb2>
    800051a6:	00000097          	auipc	ra,0x0
    800051aa:	bec080e7          	jalr	-1044(ra) # 80004d92 <filealloc>
    800051ae:	00aa3023          	sd	a0,0(s4)
    800051b2:	c92d                	beqz	a0,80005224 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	ac2080e7          	jalr	-1342(ra) # 80000c76 <kalloc>
    800051bc:	892a                	mv	s2,a0
    800051be:	c125                	beqz	a0,8000521e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800051c0:	4985                	li	s3,1
    800051c2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800051c6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800051ca:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800051ce:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800051d2:	00003597          	auipc	a1,0x3
    800051d6:	54e58593          	addi	a1,a1,1358 # 80008720 <syscalls+0x2b0>
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	b10080e7          	jalr	-1264(ra) # 80000cea <initlock>
  (*f0)->type = FD_PIPE;
    800051e2:	609c                	ld	a5,0(s1)
    800051e4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800051e8:	609c                	ld	a5,0(s1)
    800051ea:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800051ee:	609c                	ld	a5,0(s1)
    800051f0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800051f4:	609c                	ld	a5,0(s1)
    800051f6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800051fa:	000a3783          	ld	a5,0(s4)
    800051fe:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005202:	000a3783          	ld	a5,0(s4)
    80005206:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000520a:	000a3783          	ld	a5,0(s4)
    8000520e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005212:	000a3783          	ld	a5,0(s4)
    80005216:	0127b823          	sd	s2,16(a5)
  return 0;
    8000521a:	4501                	li	a0,0
    8000521c:	a025                	j	80005244 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000521e:	6088                	ld	a0,0(s1)
    80005220:	e501                	bnez	a0,80005228 <pipealloc+0xaa>
    80005222:	a039                	j	80005230 <pipealloc+0xb2>
    80005224:	6088                	ld	a0,0(s1)
    80005226:	c51d                	beqz	a0,80005254 <pipealloc+0xd6>
    fileclose(*f0);
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	c26080e7          	jalr	-986(ra) # 80004e4e <fileclose>
  if(*f1)
    80005230:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005234:	557d                	li	a0,-1
  if(*f1)
    80005236:	c799                	beqz	a5,80005244 <pipealloc+0xc6>
    fileclose(*f1);
    80005238:	853e                	mv	a0,a5
    8000523a:	00000097          	auipc	ra,0x0
    8000523e:	c14080e7          	jalr	-1004(ra) # 80004e4e <fileclose>
  return -1;
    80005242:	557d                	li	a0,-1
}
    80005244:	70a2                	ld	ra,40(sp)
    80005246:	7402                	ld	s0,32(sp)
    80005248:	64e2                	ld	s1,24(sp)
    8000524a:	6942                	ld	s2,16(sp)
    8000524c:	69a2                	ld	s3,8(sp)
    8000524e:	6a02                	ld	s4,0(sp)
    80005250:	6145                	addi	sp,sp,48
    80005252:	8082                	ret
  return -1;
    80005254:	557d                	li	a0,-1
    80005256:	b7fd                	j	80005244 <pipealloc+0xc6>

0000000080005258 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005258:	1101                	addi	sp,sp,-32
    8000525a:	ec06                	sd	ra,24(sp)
    8000525c:	e822                	sd	s0,16(sp)
    8000525e:	e426                	sd	s1,8(sp)
    80005260:	e04a                	sd	s2,0(sp)
    80005262:	1000                	addi	s0,sp,32
    80005264:	84aa                	mv	s1,a0
    80005266:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	b12080e7          	jalr	-1262(ra) # 80000d7a <acquire>
  if(writable){
    80005270:	02090d63          	beqz	s2,800052aa <pipeclose+0x52>
    pi->writeopen = 0;
    80005274:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005278:	21848513          	addi	a0,s1,536
    8000527c:	ffffd097          	auipc	ra,0xffffd
    80005280:	138080e7          	jalr	312(ra) # 800023b4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005284:	2204b783          	ld	a5,544(s1)
    80005288:	eb95                	bnez	a5,800052bc <pipeclose+0x64>
    release(&pi->lock);
    8000528a:	8526                	mv	a0,s1
    8000528c:	ffffc097          	auipc	ra,0xffffc
    80005290:	ba2080e7          	jalr	-1118(ra) # 80000e2e <release>
    kfree((char*)pi);
    80005294:	8526                	mv	a0,s1
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	89e080e7          	jalr	-1890(ra) # 80000b34 <kfree>
  } else
    release(&pi->lock);
}
    8000529e:	60e2                	ld	ra,24(sp)
    800052a0:	6442                	ld	s0,16(sp)
    800052a2:	64a2                	ld	s1,8(sp)
    800052a4:	6902                	ld	s2,0(sp)
    800052a6:	6105                	addi	sp,sp,32
    800052a8:	8082                	ret
    pi->readopen = 0;
    800052aa:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800052ae:	21c48513          	addi	a0,s1,540
    800052b2:	ffffd097          	auipc	ra,0xffffd
    800052b6:	102080e7          	jalr	258(ra) # 800023b4 <wakeup>
    800052ba:	b7e9                	j	80005284 <pipeclose+0x2c>
    release(&pi->lock);
    800052bc:	8526                	mv	a0,s1
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	b70080e7          	jalr	-1168(ra) # 80000e2e <release>
}
    800052c6:	bfe1                	j	8000529e <pipeclose+0x46>

00000000800052c8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800052c8:	711d                	addi	sp,sp,-96
    800052ca:	ec86                	sd	ra,88(sp)
    800052cc:	e8a2                	sd	s0,80(sp)
    800052ce:	e4a6                	sd	s1,72(sp)
    800052d0:	e0ca                	sd	s2,64(sp)
    800052d2:	fc4e                	sd	s3,56(sp)
    800052d4:	f852                	sd	s4,48(sp)
    800052d6:	f456                	sd	s5,40(sp)
    800052d8:	f05a                	sd	s6,32(sp)
    800052da:	ec5e                	sd	s7,24(sp)
    800052dc:	e862                	sd	s8,16(sp)
    800052de:	1080                	addi	s0,sp,96
    800052e0:	84aa                	mv	s1,a0
    800052e2:	8aae                	mv	s5,a1
    800052e4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800052e6:	ffffd097          	auipc	ra,0xffffd
    800052ea:	8ac080e7          	jalr	-1876(ra) # 80001b92 <myproc>
    800052ee:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800052f0:	8526                	mv	a0,s1
    800052f2:	ffffc097          	auipc	ra,0xffffc
    800052f6:	a88080e7          	jalr	-1400(ra) # 80000d7a <acquire>
  while(i < n){
    800052fa:	0b405663          	blez	s4,800053a6 <pipewrite+0xde>
  int i = 0;
    800052fe:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005300:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005302:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005306:	21c48b93          	addi	s7,s1,540
    8000530a:	a089                	j	8000534c <pipewrite+0x84>
      release(&pi->lock);
    8000530c:	8526                	mv	a0,s1
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	b20080e7          	jalr	-1248(ra) # 80000e2e <release>
      return -1;
    80005316:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005318:	854a                	mv	a0,s2
    8000531a:	60e6                	ld	ra,88(sp)
    8000531c:	6446                	ld	s0,80(sp)
    8000531e:	64a6                	ld	s1,72(sp)
    80005320:	6906                	ld	s2,64(sp)
    80005322:	79e2                	ld	s3,56(sp)
    80005324:	7a42                	ld	s4,48(sp)
    80005326:	7aa2                	ld	s5,40(sp)
    80005328:	7b02                	ld	s6,32(sp)
    8000532a:	6be2                	ld	s7,24(sp)
    8000532c:	6c42                	ld	s8,16(sp)
    8000532e:	6125                	addi	sp,sp,96
    80005330:	8082                	ret
      wakeup(&pi->nread);
    80005332:	8562                	mv	a0,s8
    80005334:	ffffd097          	auipc	ra,0xffffd
    80005338:	080080e7          	jalr	128(ra) # 800023b4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000533c:	85a6                	mv	a1,s1
    8000533e:	855e                	mv	a0,s7
    80005340:	ffffd097          	auipc	ra,0xffffd
    80005344:	010080e7          	jalr	16(ra) # 80002350 <sleep>
  while(i < n){
    80005348:	07495063          	bge	s2,s4,800053a8 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000534c:	2204a783          	lw	a5,544(s1)
    80005350:	dfd5                	beqz	a5,8000530c <pipewrite+0x44>
    80005352:	854e                	mv	a0,s3
    80005354:	ffffd097          	auipc	ra,0xffffd
    80005358:	2b0080e7          	jalr	688(ra) # 80002604 <killed>
    8000535c:	f945                	bnez	a0,8000530c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000535e:	2184a783          	lw	a5,536(s1)
    80005362:	21c4a703          	lw	a4,540(s1)
    80005366:	2007879b          	addiw	a5,a5,512
    8000536a:	fcf704e3          	beq	a4,a5,80005332 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000536e:	4685                	li	a3,1
    80005370:	01590633          	add	a2,s2,s5
    80005374:	faf40593          	addi	a1,s0,-81
    80005378:	0509b503          	ld	a0,80(s3)
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	562080e7          	jalr	1378(ra) # 800018de <copyin>
    80005384:	03650263          	beq	a0,s6,800053a8 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005388:	21c4a783          	lw	a5,540(s1)
    8000538c:	0017871b          	addiw	a4,a5,1
    80005390:	20e4ae23          	sw	a4,540(s1)
    80005394:	1ff7f793          	andi	a5,a5,511
    80005398:	97a6                	add	a5,a5,s1
    8000539a:	faf44703          	lbu	a4,-81(s0)
    8000539e:	00e78c23          	sb	a4,24(a5)
      i++;
    800053a2:	2905                	addiw	s2,s2,1
    800053a4:	b755                	j	80005348 <pipewrite+0x80>
  int i = 0;
    800053a6:	4901                	li	s2,0
  wakeup(&pi->nread);
    800053a8:	21848513          	addi	a0,s1,536
    800053ac:	ffffd097          	auipc	ra,0xffffd
    800053b0:	008080e7          	jalr	8(ra) # 800023b4 <wakeup>
  release(&pi->lock);
    800053b4:	8526                	mv	a0,s1
    800053b6:	ffffc097          	auipc	ra,0xffffc
    800053ba:	a78080e7          	jalr	-1416(ra) # 80000e2e <release>
  return i;
    800053be:	bfa9                	j	80005318 <pipewrite+0x50>

00000000800053c0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800053c0:	715d                	addi	sp,sp,-80
    800053c2:	e486                	sd	ra,72(sp)
    800053c4:	e0a2                	sd	s0,64(sp)
    800053c6:	fc26                	sd	s1,56(sp)
    800053c8:	f84a                	sd	s2,48(sp)
    800053ca:	f44e                	sd	s3,40(sp)
    800053cc:	f052                	sd	s4,32(sp)
    800053ce:	ec56                	sd	s5,24(sp)
    800053d0:	e85a                	sd	s6,16(sp)
    800053d2:	0880                	addi	s0,sp,80
    800053d4:	84aa                	mv	s1,a0
    800053d6:	892e                	mv	s2,a1
    800053d8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800053da:	ffffc097          	auipc	ra,0xffffc
    800053de:	7b8080e7          	jalr	1976(ra) # 80001b92 <myproc>
    800053e2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800053e4:	8526                	mv	a0,s1
    800053e6:	ffffc097          	auipc	ra,0xffffc
    800053ea:	994080e7          	jalr	-1644(ra) # 80000d7a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053ee:	2184a703          	lw	a4,536(s1)
    800053f2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053f6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053fa:	02f71763          	bne	a4,a5,80005428 <piperead+0x68>
    800053fe:	2244a783          	lw	a5,548(s1)
    80005402:	c39d                	beqz	a5,80005428 <piperead+0x68>
    if(killed(pr)){
    80005404:	8552                	mv	a0,s4
    80005406:	ffffd097          	auipc	ra,0xffffd
    8000540a:	1fe080e7          	jalr	510(ra) # 80002604 <killed>
    8000540e:	e949                	bnez	a0,800054a0 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005410:	85a6                	mv	a1,s1
    80005412:	854e                	mv	a0,s3
    80005414:	ffffd097          	auipc	ra,0xffffd
    80005418:	f3c080e7          	jalr	-196(ra) # 80002350 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000541c:	2184a703          	lw	a4,536(s1)
    80005420:	21c4a783          	lw	a5,540(s1)
    80005424:	fcf70de3          	beq	a4,a5,800053fe <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005428:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000542a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000542c:	05505463          	blez	s5,80005474 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005430:	2184a783          	lw	a5,536(s1)
    80005434:	21c4a703          	lw	a4,540(s1)
    80005438:	02f70e63          	beq	a4,a5,80005474 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000543c:	0017871b          	addiw	a4,a5,1
    80005440:	20e4ac23          	sw	a4,536(s1)
    80005444:	1ff7f793          	andi	a5,a5,511
    80005448:	97a6                	add	a5,a5,s1
    8000544a:	0187c783          	lbu	a5,24(a5)
    8000544e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005452:	4685                	li	a3,1
    80005454:	fbf40613          	addi	a2,s0,-65
    80005458:	85ca                	mv	a1,s2
    8000545a:	050a3503          	ld	a0,80(s4)
    8000545e:	ffffc097          	auipc	ra,0xffffc
    80005462:	3bc080e7          	jalr	956(ra) # 8000181a <copyout>
    80005466:	01650763          	beq	a0,s6,80005474 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000546a:	2985                	addiw	s3,s3,1
    8000546c:	0905                	addi	s2,s2,1
    8000546e:	fd3a91e3          	bne	s5,s3,80005430 <piperead+0x70>
    80005472:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005474:	21c48513          	addi	a0,s1,540
    80005478:	ffffd097          	auipc	ra,0xffffd
    8000547c:	f3c080e7          	jalr	-196(ra) # 800023b4 <wakeup>
  release(&pi->lock);
    80005480:	8526                	mv	a0,s1
    80005482:	ffffc097          	auipc	ra,0xffffc
    80005486:	9ac080e7          	jalr	-1620(ra) # 80000e2e <release>
  return i;
}
    8000548a:	854e                	mv	a0,s3
    8000548c:	60a6                	ld	ra,72(sp)
    8000548e:	6406                	ld	s0,64(sp)
    80005490:	74e2                	ld	s1,56(sp)
    80005492:	7942                	ld	s2,48(sp)
    80005494:	79a2                	ld	s3,40(sp)
    80005496:	7a02                	ld	s4,32(sp)
    80005498:	6ae2                	ld	s5,24(sp)
    8000549a:	6b42                	ld	s6,16(sp)
    8000549c:	6161                	addi	sp,sp,80
    8000549e:	8082                	ret
      release(&pi->lock);
    800054a0:	8526                	mv	a0,s1
    800054a2:	ffffc097          	auipc	ra,0xffffc
    800054a6:	98c080e7          	jalr	-1652(ra) # 80000e2e <release>
      return -1;
    800054aa:	59fd                	li	s3,-1
    800054ac:	bff9                	j	8000548a <piperead+0xca>

00000000800054ae <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800054ae:	1141                	addi	sp,sp,-16
    800054b0:	e422                	sd	s0,8(sp)
    800054b2:	0800                	addi	s0,sp,16
    800054b4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800054b6:	8905                	andi	a0,a0,1
    800054b8:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800054ba:	8b89                	andi	a5,a5,2
    800054bc:	c399                	beqz	a5,800054c2 <flags2perm+0x14>
      perm |= PTE_W;
    800054be:	00456513          	ori	a0,a0,4
    return perm;
}
    800054c2:	6422                	ld	s0,8(sp)
    800054c4:	0141                	addi	sp,sp,16
    800054c6:	8082                	ret

00000000800054c8 <exec>:

int
exec(char *path, char **argv)
{
    800054c8:	de010113          	addi	sp,sp,-544
    800054cc:	20113c23          	sd	ra,536(sp)
    800054d0:	20813823          	sd	s0,528(sp)
    800054d4:	20913423          	sd	s1,520(sp)
    800054d8:	21213023          	sd	s2,512(sp)
    800054dc:	ffce                	sd	s3,504(sp)
    800054de:	fbd2                	sd	s4,496(sp)
    800054e0:	f7d6                	sd	s5,488(sp)
    800054e2:	f3da                	sd	s6,480(sp)
    800054e4:	efde                	sd	s7,472(sp)
    800054e6:	ebe2                	sd	s8,464(sp)
    800054e8:	e7e6                	sd	s9,456(sp)
    800054ea:	e3ea                	sd	s10,448(sp)
    800054ec:	ff6e                	sd	s11,440(sp)
    800054ee:	1400                	addi	s0,sp,544
    800054f0:	892a                	mv	s2,a0
    800054f2:	dea43423          	sd	a0,-536(s0)
    800054f6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800054fa:	ffffc097          	auipc	ra,0xffffc
    800054fe:	698080e7          	jalr	1688(ra) # 80001b92 <myproc>
    80005502:	84aa                	mv	s1,a0

  begin_op();
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	482080e7          	jalr	1154(ra) # 80004986 <begin_op>

  if((ip = namei(path)) == 0){
    8000550c:	854a                	mv	a0,s2
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	258080e7          	jalr	600(ra) # 80004766 <namei>
    80005516:	c93d                	beqz	a0,8000558c <exec+0xc4>
    80005518:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	aa0080e7          	jalr	-1376(ra) # 80003fba <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005522:	04000713          	li	a4,64
    80005526:	4681                	li	a3,0
    80005528:	e5040613          	addi	a2,s0,-432
    8000552c:	4581                	li	a1,0
    8000552e:	8556                	mv	a0,s5
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	d3e080e7          	jalr	-706(ra) # 8000426e <readi>
    80005538:	04000793          	li	a5,64
    8000553c:	00f51a63          	bne	a0,a5,80005550 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005540:	e5042703          	lw	a4,-432(s0)
    80005544:	464c47b7          	lui	a5,0x464c4
    80005548:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000554c:	04f70663          	beq	a4,a5,80005598 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005550:	8556                	mv	a0,s5
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	cca080e7          	jalr	-822(ra) # 8000421c <iunlockput>
    end_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	4aa080e7          	jalr	1194(ra) # 80004a04 <end_op>
  }
  return -1;
    80005562:	557d                	li	a0,-1
}
    80005564:	21813083          	ld	ra,536(sp)
    80005568:	21013403          	ld	s0,528(sp)
    8000556c:	20813483          	ld	s1,520(sp)
    80005570:	20013903          	ld	s2,512(sp)
    80005574:	79fe                	ld	s3,504(sp)
    80005576:	7a5e                	ld	s4,496(sp)
    80005578:	7abe                	ld	s5,488(sp)
    8000557a:	7b1e                	ld	s6,480(sp)
    8000557c:	6bfe                	ld	s7,472(sp)
    8000557e:	6c5e                	ld	s8,464(sp)
    80005580:	6cbe                	ld	s9,456(sp)
    80005582:	6d1e                	ld	s10,448(sp)
    80005584:	7dfa                	ld	s11,440(sp)
    80005586:	22010113          	addi	sp,sp,544
    8000558a:	8082                	ret
    end_op();
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	478080e7          	jalr	1144(ra) # 80004a04 <end_op>
    return -1;
    80005594:	557d                	li	a0,-1
    80005596:	b7f9                	j	80005564 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005598:	8526                	mv	a0,s1
    8000559a:	ffffc097          	auipc	ra,0xffffc
    8000559e:	6bc080e7          	jalr	1724(ra) # 80001c56 <proc_pagetable>
    800055a2:	8b2a                	mv	s6,a0
    800055a4:	d555                	beqz	a0,80005550 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055a6:	e7042783          	lw	a5,-400(s0)
    800055aa:	e8845703          	lhu	a4,-376(s0)
    800055ae:	c735                	beqz	a4,8000561a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800055b0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055b2:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800055b6:	6a05                	lui	s4,0x1
    800055b8:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800055bc:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800055c0:	6d85                	lui	s11,0x1
    800055c2:	7d7d                	lui	s10,0xfffff
    800055c4:	ac3d                	j	80005802 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800055c6:	00003517          	auipc	a0,0x3
    800055ca:	16250513          	addi	a0,a0,354 # 80008728 <syscalls+0x2b8>
    800055ce:	ffffb097          	auipc	ra,0xffffb
    800055d2:	f72080e7          	jalr	-142(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800055d6:	874a                	mv	a4,s2
    800055d8:	009c86bb          	addw	a3,s9,s1
    800055dc:	4581                	li	a1,0
    800055de:	8556                	mv	a0,s5
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	c8e080e7          	jalr	-882(ra) # 8000426e <readi>
    800055e8:	2501                	sext.w	a0,a0
    800055ea:	1aa91963          	bne	s2,a0,8000579c <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800055ee:	009d84bb          	addw	s1,s11,s1
    800055f2:	013d09bb          	addw	s3,s10,s3
    800055f6:	1f74f663          	bgeu	s1,s7,800057e2 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    800055fa:	02049593          	slli	a1,s1,0x20
    800055fe:	9181                	srli	a1,a1,0x20
    80005600:	95e2                	add	a1,a1,s8
    80005602:	855a                	mv	a0,s6
    80005604:	ffffc097          	auipc	ra,0xffffc
    80005608:	bfc080e7          	jalr	-1028(ra) # 80001200 <walkaddr>
    8000560c:	862a                	mv	a2,a0
    if(pa == 0)
    8000560e:	dd45                	beqz	a0,800055c6 <exec+0xfe>
      n = PGSIZE;
    80005610:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005612:	fd49f2e3          	bgeu	s3,s4,800055d6 <exec+0x10e>
      n = sz - i;
    80005616:	894e                	mv	s2,s3
    80005618:	bf7d                	j	800055d6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000561a:	4901                	li	s2,0
  iunlockput(ip);
    8000561c:	8556                	mv	a0,s5
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	bfe080e7          	jalr	-1026(ra) # 8000421c <iunlockput>
  end_op();
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	3de080e7          	jalr	990(ra) # 80004a04 <end_op>
  p = myproc();
    8000562e:	ffffc097          	auipc	ra,0xffffc
    80005632:	564080e7          	jalr	1380(ra) # 80001b92 <myproc>
    80005636:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005638:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000563c:	6785                	lui	a5,0x1
    8000563e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005640:	97ca                	add	a5,a5,s2
    80005642:	777d                	lui	a4,0xfffff
    80005644:	8ff9                	and	a5,a5,a4
    80005646:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000564a:	4691                	li	a3,4
    8000564c:	6609                	lui	a2,0x2
    8000564e:	963e                	add	a2,a2,a5
    80005650:	85be                	mv	a1,a5
    80005652:	855a                	mv	a0,s6
    80005654:	ffffc097          	auipc	ra,0xffffc
    80005658:	f60080e7          	jalr	-160(ra) # 800015b4 <uvmalloc>
    8000565c:	8c2a                	mv	s8,a0
  ip = 0;
    8000565e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005660:	12050e63          	beqz	a0,8000579c <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005664:	75f9                	lui	a1,0xffffe
    80005666:	95aa                	add	a1,a1,a0
    80005668:	855a                	mv	a0,s6
    8000566a:	ffffc097          	auipc	ra,0xffffc
    8000566e:	17e080e7          	jalr	382(ra) # 800017e8 <uvmclear>
  stackbase = sp - PGSIZE;
    80005672:	7afd                	lui	s5,0xfffff
    80005674:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005676:	df043783          	ld	a5,-528(s0)
    8000567a:	6388                	ld	a0,0(a5)
    8000567c:	c925                	beqz	a0,800056ec <exec+0x224>
    8000567e:	e9040993          	addi	s3,s0,-368
    80005682:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005686:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005688:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000568a:	ffffc097          	auipc	ra,0xffffc
    8000568e:	968080e7          	jalr	-1688(ra) # 80000ff2 <strlen>
    80005692:	0015079b          	addiw	a5,a0,1
    80005696:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000569a:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000569e:	13596663          	bltu	s2,s5,800057ca <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800056a2:	df043d83          	ld	s11,-528(s0)
    800056a6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800056aa:	8552                	mv	a0,s4
    800056ac:	ffffc097          	auipc	ra,0xffffc
    800056b0:	946080e7          	jalr	-1722(ra) # 80000ff2 <strlen>
    800056b4:	0015069b          	addiw	a3,a0,1
    800056b8:	8652                	mv	a2,s4
    800056ba:	85ca                	mv	a1,s2
    800056bc:	855a                	mv	a0,s6
    800056be:	ffffc097          	auipc	ra,0xffffc
    800056c2:	15c080e7          	jalr	348(ra) # 8000181a <copyout>
    800056c6:	10054663          	bltz	a0,800057d2 <exec+0x30a>
    ustack[argc] = sp;
    800056ca:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056ce:	0485                	addi	s1,s1,1
    800056d0:	008d8793          	addi	a5,s11,8
    800056d4:	def43823          	sd	a5,-528(s0)
    800056d8:	008db503          	ld	a0,8(s11)
    800056dc:	c911                	beqz	a0,800056f0 <exec+0x228>
    if(argc >= MAXARG)
    800056de:	09a1                	addi	s3,s3,8
    800056e0:	fb3c95e3          	bne	s9,s3,8000568a <exec+0x1c2>
  sz = sz1;
    800056e4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056e8:	4a81                	li	s5,0
    800056ea:	a84d                	j	8000579c <exec+0x2d4>
  sp = sz;
    800056ec:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800056ee:	4481                	li	s1,0
  ustack[argc] = 0;
    800056f0:	00349793          	slli	a5,s1,0x3
    800056f4:	f9078793          	addi	a5,a5,-112
    800056f8:	97a2                	add	a5,a5,s0
    800056fa:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800056fe:	00148693          	addi	a3,s1,1
    80005702:	068e                	slli	a3,a3,0x3
    80005704:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005708:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000570c:	01597663          	bgeu	s2,s5,80005718 <exec+0x250>
  sz = sz1;
    80005710:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005714:	4a81                	li	s5,0
    80005716:	a059                	j	8000579c <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005718:	e9040613          	addi	a2,s0,-368
    8000571c:	85ca                	mv	a1,s2
    8000571e:	855a                	mv	a0,s6
    80005720:	ffffc097          	auipc	ra,0xffffc
    80005724:	0fa080e7          	jalr	250(ra) # 8000181a <copyout>
    80005728:	0a054963          	bltz	a0,800057da <exec+0x312>
  p->trapframe->a1 = sp;
    8000572c:	058bb783          	ld	a5,88(s7)
    80005730:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005734:	de843783          	ld	a5,-536(s0)
    80005738:	0007c703          	lbu	a4,0(a5)
    8000573c:	cf11                	beqz	a4,80005758 <exec+0x290>
    8000573e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005740:	02f00693          	li	a3,47
    80005744:	a039                	j	80005752 <exec+0x28a>
      last = s+1;
    80005746:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000574a:	0785                	addi	a5,a5,1
    8000574c:	fff7c703          	lbu	a4,-1(a5)
    80005750:	c701                	beqz	a4,80005758 <exec+0x290>
    if(*s == '/')
    80005752:	fed71ce3          	bne	a4,a3,8000574a <exec+0x282>
    80005756:	bfc5                	j	80005746 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005758:	4641                	li	a2,16
    8000575a:	de843583          	ld	a1,-536(s0)
    8000575e:	158b8513          	addi	a0,s7,344
    80005762:	ffffc097          	auipc	ra,0xffffc
    80005766:	85e080e7          	jalr	-1954(ra) # 80000fc0 <safestrcpy>
  oldpagetable = p->pagetable;
    8000576a:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000576e:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005772:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005776:	058bb783          	ld	a5,88(s7)
    8000577a:	e6843703          	ld	a4,-408(s0)
    8000577e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005780:	058bb783          	ld	a5,88(s7)
    80005784:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005788:	85ea                	mv	a1,s10
    8000578a:	ffffc097          	auipc	ra,0xffffc
    8000578e:	568080e7          	jalr	1384(ra) # 80001cf2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005792:	0004851b          	sext.w	a0,s1
    80005796:	b3f9                	j	80005564 <exec+0x9c>
    80005798:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000579c:	df843583          	ld	a1,-520(s0)
    800057a0:	855a                	mv	a0,s6
    800057a2:	ffffc097          	auipc	ra,0xffffc
    800057a6:	550080e7          	jalr	1360(ra) # 80001cf2 <proc_freepagetable>
  if(ip){
    800057aa:	da0a93e3          	bnez	s5,80005550 <exec+0x88>
  return -1;
    800057ae:	557d                	li	a0,-1
    800057b0:	bb55                	j	80005564 <exec+0x9c>
    800057b2:	df243c23          	sd	s2,-520(s0)
    800057b6:	b7dd                	j	8000579c <exec+0x2d4>
    800057b8:	df243c23          	sd	s2,-520(s0)
    800057bc:	b7c5                	j	8000579c <exec+0x2d4>
    800057be:	df243c23          	sd	s2,-520(s0)
    800057c2:	bfe9                	j	8000579c <exec+0x2d4>
    800057c4:	df243c23          	sd	s2,-520(s0)
    800057c8:	bfd1                	j	8000579c <exec+0x2d4>
  sz = sz1;
    800057ca:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800057ce:	4a81                	li	s5,0
    800057d0:	b7f1                	j	8000579c <exec+0x2d4>
  sz = sz1;
    800057d2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800057d6:	4a81                	li	s5,0
    800057d8:	b7d1                	j	8000579c <exec+0x2d4>
  sz = sz1;
    800057da:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800057de:	4a81                	li	s5,0
    800057e0:	bf75                	j	8000579c <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800057e2:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057e6:	e0843783          	ld	a5,-504(s0)
    800057ea:	0017869b          	addiw	a3,a5,1
    800057ee:	e0d43423          	sd	a3,-504(s0)
    800057f2:	e0043783          	ld	a5,-512(s0)
    800057f6:	0387879b          	addiw	a5,a5,56
    800057fa:	e8845703          	lhu	a4,-376(s0)
    800057fe:	e0e6dfe3          	bge	a3,a4,8000561c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005802:	2781                	sext.w	a5,a5
    80005804:	e0f43023          	sd	a5,-512(s0)
    80005808:	03800713          	li	a4,56
    8000580c:	86be                	mv	a3,a5
    8000580e:	e1840613          	addi	a2,s0,-488
    80005812:	4581                	li	a1,0
    80005814:	8556                	mv	a0,s5
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	a58080e7          	jalr	-1448(ra) # 8000426e <readi>
    8000581e:	03800793          	li	a5,56
    80005822:	f6f51be3          	bne	a0,a5,80005798 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005826:	e1842783          	lw	a5,-488(s0)
    8000582a:	4705                	li	a4,1
    8000582c:	fae79de3          	bne	a5,a4,800057e6 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005830:	e4043483          	ld	s1,-448(s0)
    80005834:	e3843783          	ld	a5,-456(s0)
    80005838:	f6f4ede3          	bltu	s1,a5,800057b2 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000583c:	e2843783          	ld	a5,-472(s0)
    80005840:	94be                	add	s1,s1,a5
    80005842:	f6f4ebe3          	bltu	s1,a5,800057b8 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005846:	de043703          	ld	a4,-544(s0)
    8000584a:	8ff9                	and	a5,a5,a4
    8000584c:	fbad                	bnez	a5,800057be <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000584e:	e1c42503          	lw	a0,-484(s0)
    80005852:	00000097          	auipc	ra,0x0
    80005856:	c5c080e7          	jalr	-932(ra) # 800054ae <flags2perm>
    8000585a:	86aa                	mv	a3,a0
    8000585c:	8626                	mv	a2,s1
    8000585e:	85ca                	mv	a1,s2
    80005860:	855a                	mv	a0,s6
    80005862:	ffffc097          	auipc	ra,0xffffc
    80005866:	d52080e7          	jalr	-686(ra) # 800015b4 <uvmalloc>
    8000586a:	dea43c23          	sd	a0,-520(s0)
    8000586e:	d939                	beqz	a0,800057c4 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005870:	e2843c03          	ld	s8,-472(s0)
    80005874:	e2042c83          	lw	s9,-480(s0)
    80005878:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000587c:	f60b83e3          	beqz	s7,800057e2 <exec+0x31a>
    80005880:	89de                	mv	s3,s7
    80005882:	4481                	li	s1,0
    80005884:	bb9d                	j	800055fa <exec+0x132>

0000000080005886 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005886:	7179                	addi	sp,sp,-48
    80005888:	f406                	sd	ra,40(sp)
    8000588a:	f022                	sd	s0,32(sp)
    8000588c:	ec26                	sd	s1,24(sp)
    8000588e:	e84a                	sd	s2,16(sp)
    80005890:	1800                	addi	s0,sp,48
    80005892:	892e                	mv	s2,a1
    80005894:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005896:	fdc40593          	addi	a1,s0,-36
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	902080e7          	jalr	-1790(ra) # 8000319c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800058a2:	fdc42703          	lw	a4,-36(s0)
    800058a6:	47bd                	li	a5,15
    800058a8:	02e7eb63          	bltu	a5,a4,800058de <argfd+0x58>
    800058ac:	ffffc097          	auipc	ra,0xffffc
    800058b0:	2e6080e7          	jalr	742(ra) # 80001b92 <myproc>
    800058b4:	fdc42703          	lw	a4,-36(s0)
    800058b8:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbba42>
    800058bc:	078e                	slli	a5,a5,0x3
    800058be:	953e                	add	a0,a0,a5
    800058c0:	611c                	ld	a5,0(a0)
    800058c2:	c385                	beqz	a5,800058e2 <argfd+0x5c>
    return -1;
  if(pfd)
    800058c4:	00090463          	beqz	s2,800058cc <argfd+0x46>
    *pfd = fd;
    800058c8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800058cc:	4501                	li	a0,0
  if(pf)
    800058ce:	c091                	beqz	s1,800058d2 <argfd+0x4c>
    *pf = f;
    800058d0:	e09c                	sd	a5,0(s1)
}
    800058d2:	70a2                	ld	ra,40(sp)
    800058d4:	7402                	ld	s0,32(sp)
    800058d6:	64e2                	ld	s1,24(sp)
    800058d8:	6942                	ld	s2,16(sp)
    800058da:	6145                	addi	sp,sp,48
    800058dc:	8082                	ret
    return -1;
    800058de:	557d                	li	a0,-1
    800058e0:	bfcd                	j	800058d2 <argfd+0x4c>
    800058e2:	557d                	li	a0,-1
    800058e4:	b7fd                	j	800058d2 <argfd+0x4c>

00000000800058e6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800058e6:	1101                	addi	sp,sp,-32
    800058e8:	ec06                	sd	ra,24(sp)
    800058ea:	e822                	sd	s0,16(sp)
    800058ec:	e426                	sd	s1,8(sp)
    800058ee:	1000                	addi	s0,sp,32
    800058f0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800058f2:	ffffc097          	auipc	ra,0xffffc
    800058f6:	2a0080e7          	jalr	672(ra) # 80001b92 <myproc>
    800058fa:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800058fc:	0d050793          	addi	a5,a0,208
    80005900:	4501                	li	a0,0
    80005902:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005904:	6398                	ld	a4,0(a5)
    80005906:	cb19                	beqz	a4,8000591c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005908:	2505                	addiw	a0,a0,1
    8000590a:	07a1                	addi	a5,a5,8
    8000590c:	fed51ce3          	bne	a0,a3,80005904 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005910:	557d                	li	a0,-1
}
    80005912:	60e2                	ld	ra,24(sp)
    80005914:	6442                	ld	s0,16(sp)
    80005916:	64a2                	ld	s1,8(sp)
    80005918:	6105                	addi	sp,sp,32
    8000591a:	8082                	ret
      p->ofile[fd] = f;
    8000591c:	01a50793          	addi	a5,a0,26
    80005920:	078e                	slli	a5,a5,0x3
    80005922:	963e                	add	a2,a2,a5
    80005924:	e204                	sd	s1,0(a2)
      return fd;
    80005926:	b7f5                	j	80005912 <fdalloc+0x2c>

0000000080005928 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005928:	715d                	addi	sp,sp,-80
    8000592a:	e486                	sd	ra,72(sp)
    8000592c:	e0a2                	sd	s0,64(sp)
    8000592e:	fc26                	sd	s1,56(sp)
    80005930:	f84a                	sd	s2,48(sp)
    80005932:	f44e                	sd	s3,40(sp)
    80005934:	f052                	sd	s4,32(sp)
    80005936:	ec56                	sd	s5,24(sp)
    80005938:	e85a                	sd	s6,16(sp)
    8000593a:	0880                	addi	s0,sp,80
    8000593c:	8b2e                	mv	s6,a1
    8000593e:	89b2                	mv	s3,a2
    80005940:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005942:	fb040593          	addi	a1,s0,-80
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	e3e080e7          	jalr	-450(ra) # 80004784 <nameiparent>
    8000594e:	84aa                	mv	s1,a0
    80005950:	14050f63          	beqz	a0,80005aae <create+0x186>
    return 0;

  ilock(dp);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	666080e7          	jalr	1638(ra) # 80003fba <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000595c:	4601                	li	a2,0
    8000595e:	fb040593          	addi	a1,s0,-80
    80005962:	8526                	mv	a0,s1
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	b3a080e7          	jalr	-1222(ra) # 8000449e <dirlookup>
    8000596c:	8aaa                	mv	s5,a0
    8000596e:	c931                	beqz	a0,800059c2 <create+0x9a>
    iunlockput(dp);
    80005970:	8526                	mv	a0,s1
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	8aa080e7          	jalr	-1878(ra) # 8000421c <iunlockput>
    ilock(ip);
    8000597a:	8556                	mv	a0,s5
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	63e080e7          	jalr	1598(ra) # 80003fba <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005984:	000b059b          	sext.w	a1,s6
    80005988:	4789                	li	a5,2
    8000598a:	02f59563          	bne	a1,a5,800059b4 <create+0x8c>
    8000598e:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbba6c>
    80005992:	37f9                	addiw	a5,a5,-2
    80005994:	17c2                	slli	a5,a5,0x30
    80005996:	93c1                	srli	a5,a5,0x30
    80005998:	4705                	li	a4,1
    8000599a:	00f76d63          	bltu	a4,a5,800059b4 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000599e:	8556                	mv	a0,s5
    800059a0:	60a6                	ld	ra,72(sp)
    800059a2:	6406                	ld	s0,64(sp)
    800059a4:	74e2                	ld	s1,56(sp)
    800059a6:	7942                	ld	s2,48(sp)
    800059a8:	79a2                	ld	s3,40(sp)
    800059aa:	7a02                	ld	s4,32(sp)
    800059ac:	6ae2                	ld	s5,24(sp)
    800059ae:	6b42                	ld	s6,16(sp)
    800059b0:	6161                	addi	sp,sp,80
    800059b2:	8082                	ret
    iunlockput(ip);
    800059b4:	8556                	mv	a0,s5
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	866080e7          	jalr	-1946(ra) # 8000421c <iunlockput>
    return 0;
    800059be:	4a81                	li	s5,0
    800059c0:	bff9                	j	8000599e <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800059c2:	85da                	mv	a1,s6
    800059c4:	4088                	lw	a0,0(s1)
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	456080e7          	jalr	1110(ra) # 80003e1c <ialloc>
    800059ce:	8a2a                	mv	s4,a0
    800059d0:	c539                	beqz	a0,80005a1e <create+0xf6>
  ilock(ip);
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	5e8080e7          	jalr	1512(ra) # 80003fba <ilock>
  ip->major = major;
    800059da:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800059de:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800059e2:	4905                	li	s2,1
    800059e4:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800059e8:	8552                	mv	a0,s4
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	504080e7          	jalr	1284(ra) # 80003eee <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800059f2:	000b059b          	sext.w	a1,s6
    800059f6:	03258b63          	beq	a1,s2,80005a2c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800059fa:	004a2603          	lw	a2,4(s4)
    800059fe:	fb040593          	addi	a1,s0,-80
    80005a02:	8526                	mv	a0,s1
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	cb0080e7          	jalr	-848(ra) # 800046b4 <dirlink>
    80005a0c:	06054f63          	bltz	a0,80005a8a <create+0x162>
  iunlockput(dp);
    80005a10:	8526                	mv	a0,s1
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	80a080e7          	jalr	-2038(ra) # 8000421c <iunlockput>
  return ip;
    80005a1a:	8ad2                	mv	s5,s4
    80005a1c:	b749                	j	8000599e <create+0x76>
    iunlockput(dp);
    80005a1e:	8526                	mv	a0,s1
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	7fc080e7          	jalr	2044(ra) # 8000421c <iunlockput>
    return 0;
    80005a28:	8ad2                	mv	s5,s4
    80005a2a:	bf95                	j	8000599e <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a2c:	004a2603          	lw	a2,4(s4)
    80005a30:	00003597          	auipc	a1,0x3
    80005a34:	d1858593          	addi	a1,a1,-744 # 80008748 <syscalls+0x2d8>
    80005a38:	8552                	mv	a0,s4
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	c7a080e7          	jalr	-902(ra) # 800046b4 <dirlink>
    80005a42:	04054463          	bltz	a0,80005a8a <create+0x162>
    80005a46:	40d0                	lw	a2,4(s1)
    80005a48:	00003597          	auipc	a1,0x3
    80005a4c:	d0858593          	addi	a1,a1,-760 # 80008750 <syscalls+0x2e0>
    80005a50:	8552                	mv	a0,s4
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	c62080e7          	jalr	-926(ra) # 800046b4 <dirlink>
    80005a5a:	02054863          	bltz	a0,80005a8a <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a5e:	004a2603          	lw	a2,4(s4)
    80005a62:	fb040593          	addi	a1,s0,-80
    80005a66:	8526                	mv	a0,s1
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	c4c080e7          	jalr	-948(ra) # 800046b4 <dirlink>
    80005a70:	00054d63          	bltz	a0,80005a8a <create+0x162>
    dp->nlink++;  // for ".."
    80005a74:	04a4d783          	lhu	a5,74(s1)
    80005a78:	2785                	addiw	a5,a5,1
    80005a7a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a7e:	8526                	mv	a0,s1
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	46e080e7          	jalr	1134(ra) # 80003eee <iupdate>
    80005a88:	b761                	j	80005a10 <create+0xe8>
  ip->nlink = 0;
    80005a8a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005a8e:	8552                	mv	a0,s4
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	45e080e7          	jalr	1118(ra) # 80003eee <iupdate>
  iunlockput(ip);
    80005a98:	8552                	mv	a0,s4
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	782080e7          	jalr	1922(ra) # 8000421c <iunlockput>
  iunlockput(dp);
    80005aa2:	8526                	mv	a0,s1
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	778080e7          	jalr	1912(ra) # 8000421c <iunlockput>
  return 0;
    80005aac:	bdcd                	j	8000599e <create+0x76>
    return 0;
    80005aae:	8aaa                	mv	s5,a0
    80005ab0:	b5fd                	j	8000599e <create+0x76>

0000000080005ab2 <sys_dup>:
{
    80005ab2:	7179                	addi	sp,sp,-48
    80005ab4:	f406                	sd	ra,40(sp)
    80005ab6:	f022                	sd	s0,32(sp)
    80005ab8:	ec26                	sd	s1,24(sp)
    80005aba:	e84a                	sd	s2,16(sp)
    80005abc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005abe:	fd840613          	addi	a2,s0,-40
    80005ac2:	4581                	li	a1,0
    80005ac4:	4501                	li	a0,0
    80005ac6:	00000097          	auipc	ra,0x0
    80005aca:	dc0080e7          	jalr	-576(ra) # 80005886 <argfd>
    return -1;
    80005ace:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005ad0:	02054363          	bltz	a0,80005af6 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005ad4:	fd843903          	ld	s2,-40(s0)
    80005ad8:	854a                	mv	a0,s2
    80005ada:	00000097          	auipc	ra,0x0
    80005ade:	e0c080e7          	jalr	-500(ra) # 800058e6 <fdalloc>
    80005ae2:	84aa                	mv	s1,a0
    return -1;
    80005ae4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005ae6:	00054863          	bltz	a0,80005af6 <sys_dup+0x44>
  filedup(f);
    80005aea:	854a                	mv	a0,s2
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	310080e7          	jalr	784(ra) # 80004dfc <filedup>
  return fd;
    80005af4:	87a6                	mv	a5,s1
}
    80005af6:	853e                	mv	a0,a5
    80005af8:	70a2                	ld	ra,40(sp)
    80005afa:	7402                	ld	s0,32(sp)
    80005afc:	64e2                	ld	s1,24(sp)
    80005afe:	6942                	ld	s2,16(sp)
    80005b00:	6145                	addi	sp,sp,48
    80005b02:	8082                	ret

0000000080005b04 <sys_read>:
{
    80005b04:	7179                	addi	sp,sp,-48
    80005b06:	f406                	sd	ra,40(sp)
    80005b08:	f022                	sd	s0,32(sp)
    80005b0a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005b0c:	fd840593          	addi	a1,s0,-40
    80005b10:	4505                	li	a0,1
    80005b12:	ffffd097          	auipc	ra,0xffffd
    80005b16:	6aa080e7          	jalr	1706(ra) # 800031bc <argaddr>
  argint(2, &n);
    80005b1a:	fe440593          	addi	a1,s0,-28
    80005b1e:	4509                	li	a0,2
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	67c080e7          	jalr	1660(ra) # 8000319c <argint>
  if(argfd(0, 0, &f) < 0)
    80005b28:	fe840613          	addi	a2,s0,-24
    80005b2c:	4581                	li	a1,0
    80005b2e:	4501                	li	a0,0
    80005b30:	00000097          	auipc	ra,0x0
    80005b34:	d56080e7          	jalr	-682(ra) # 80005886 <argfd>
    80005b38:	87aa                	mv	a5,a0
    return -1;
    80005b3a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b3c:	0007cc63          	bltz	a5,80005b54 <sys_read+0x50>
  return fileread(f, p, n);
    80005b40:	fe442603          	lw	a2,-28(s0)
    80005b44:	fd843583          	ld	a1,-40(s0)
    80005b48:	fe843503          	ld	a0,-24(s0)
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	43c080e7          	jalr	1084(ra) # 80004f88 <fileread>
}
    80005b54:	70a2                	ld	ra,40(sp)
    80005b56:	7402                	ld	s0,32(sp)
    80005b58:	6145                	addi	sp,sp,48
    80005b5a:	8082                	ret

0000000080005b5c <sys_write>:
{
    80005b5c:	7179                	addi	sp,sp,-48
    80005b5e:	f406                	sd	ra,40(sp)
    80005b60:	f022                	sd	s0,32(sp)
    80005b62:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005b64:	fd840593          	addi	a1,s0,-40
    80005b68:	4505                	li	a0,1
    80005b6a:	ffffd097          	auipc	ra,0xffffd
    80005b6e:	652080e7          	jalr	1618(ra) # 800031bc <argaddr>
  argint(2, &n);
    80005b72:	fe440593          	addi	a1,s0,-28
    80005b76:	4509                	li	a0,2
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	624080e7          	jalr	1572(ra) # 8000319c <argint>
  if(argfd(0, 0, &f) < 0)
    80005b80:	fe840613          	addi	a2,s0,-24
    80005b84:	4581                	li	a1,0
    80005b86:	4501                	li	a0,0
    80005b88:	00000097          	auipc	ra,0x0
    80005b8c:	cfe080e7          	jalr	-770(ra) # 80005886 <argfd>
    80005b90:	87aa                	mv	a5,a0
    return -1;
    80005b92:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b94:	0007cc63          	bltz	a5,80005bac <sys_write+0x50>
  return filewrite(f, p, n);
    80005b98:	fe442603          	lw	a2,-28(s0)
    80005b9c:	fd843583          	ld	a1,-40(s0)
    80005ba0:	fe843503          	ld	a0,-24(s0)
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	4a6080e7          	jalr	1190(ra) # 8000504a <filewrite>
}
    80005bac:	70a2                	ld	ra,40(sp)
    80005bae:	7402                	ld	s0,32(sp)
    80005bb0:	6145                	addi	sp,sp,48
    80005bb2:	8082                	ret

0000000080005bb4 <sys_close>:
{
    80005bb4:	1101                	addi	sp,sp,-32
    80005bb6:	ec06                	sd	ra,24(sp)
    80005bb8:	e822                	sd	s0,16(sp)
    80005bba:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005bbc:	fe040613          	addi	a2,s0,-32
    80005bc0:	fec40593          	addi	a1,s0,-20
    80005bc4:	4501                	li	a0,0
    80005bc6:	00000097          	auipc	ra,0x0
    80005bca:	cc0080e7          	jalr	-832(ra) # 80005886 <argfd>
    return -1;
    80005bce:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005bd0:	02054463          	bltz	a0,80005bf8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005bd4:	ffffc097          	auipc	ra,0xffffc
    80005bd8:	fbe080e7          	jalr	-66(ra) # 80001b92 <myproc>
    80005bdc:	fec42783          	lw	a5,-20(s0)
    80005be0:	07e9                	addi	a5,a5,26
    80005be2:	078e                	slli	a5,a5,0x3
    80005be4:	953e                	add	a0,a0,a5
    80005be6:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005bea:	fe043503          	ld	a0,-32(s0)
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	260080e7          	jalr	608(ra) # 80004e4e <fileclose>
  return 0;
    80005bf6:	4781                	li	a5,0
}
    80005bf8:	853e                	mv	a0,a5
    80005bfa:	60e2                	ld	ra,24(sp)
    80005bfc:	6442                	ld	s0,16(sp)
    80005bfe:	6105                	addi	sp,sp,32
    80005c00:	8082                	ret

0000000080005c02 <sys_fstat>:
{
    80005c02:	1101                	addi	sp,sp,-32
    80005c04:	ec06                	sd	ra,24(sp)
    80005c06:	e822                	sd	s0,16(sp)
    80005c08:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005c0a:	fe040593          	addi	a1,s0,-32
    80005c0e:	4505                	li	a0,1
    80005c10:	ffffd097          	auipc	ra,0xffffd
    80005c14:	5ac080e7          	jalr	1452(ra) # 800031bc <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005c18:	fe840613          	addi	a2,s0,-24
    80005c1c:	4581                	li	a1,0
    80005c1e:	4501                	li	a0,0
    80005c20:	00000097          	auipc	ra,0x0
    80005c24:	c66080e7          	jalr	-922(ra) # 80005886 <argfd>
    80005c28:	87aa                	mv	a5,a0
    return -1;
    80005c2a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005c2c:	0007ca63          	bltz	a5,80005c40 <sys_fstat+0x3e>
  return filestat(f, st);
    80005c30:	fe043583          	ld	a1,-32(s0)
    80005c34:	fe843503          	ld	a0,-24(s0)
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	2de080e7          	jalr	734(ra) # 80004f16 <filestat>
}
    80005c40:	60e2                	ld	ra,24(sp)
    80005c42:	6442                	ld	s0,16(sp)
    80005c44:	6105                	addi	sp,sp,32
    80005c46:	8082                	ret

0000000080005c48 <sys_link>:
{
    80005c48:	7169                	addi	sp,sp,-304
    80005c4a:	f606                	sd	ra,296(sp)
    80005c4c:	f222                	sd	s0,288(sp)
    80005c4e:	ee26                	sd	s1,280(sp)
    80005c50:	ea4a                	sd	s2,272(sp)
    80005c52:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c54:	08000613          	li	a2,128
    80005c58:	ed040593          	addi	a1,s0,-304
    80005c5c:	4501                	li	a0,0
    80005c5e:	ffffd097          	auipc	ra,0xffffd
    80005c62:	57e080e7          	jalr	1406(ra) # 800031dc <argstr>
    return -1;
    80005c66:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c68:	10054e63          	bltz	a0,80005d84 <sys_link+0x13c>
    80005c6c:	08000613          	li	a2,128
    80005c70:	f5040593          	addi	a1,s0,-176
    80005c74:	4505                	li	a0,1
    80005c76:	ffffd097          	auipc	ra,0xffffd
    80005c7a:	566080e7          	jalr	1382(ra) # 800031dc <argstr>
    return -1;
    80005c7e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c80:	10054263          	bltz	a0,80005d84 <sys_link+0x13c>
  begin_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	d02080e7          	jalr	-766(ra) # 80004986 <begin_op>
  if((ip = namei(old)) == 0){
    80005c8c:	ed040513          	addi	a0,s0,-304
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	ad6080e7          	jalr	-1322(ra) # 80004766 <namei>
    80005c98:	84aa                	mv	s1,a0
    80005c9a:	c551                	beqz	a0,80005d26 <sys_link+0xde>
  ilock(ip);
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	31e080e7          	jalr	798(ra) # 80003fba <ilock>
  if(ip->type == T_DIR){
    80005ca4:	04449703          	lh	a4,68(s1)
    80005ca8:	4785                	li	a5,1
    80005caa:	08f70463          	beq	a4,a5,80005d32 <sys_link+0xea>
  ip->nlink++;
    80005cae:	04a4d783          	lhu	a5,74(s1)
    80005cb2:	2785                	addiw	a5,a5,1
    80005cb4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cb8:	8526                	mv	a0,s1
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	234080e7          	jalr	564(ra) # 80003eee <iupdate>
  iunlock(ip);
    80005cc2:	8526                	mv	a0,s1
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	3b8080e7          	jalr	952(ra) # 8000407c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ccc:	fd040593          	addi	a1,s0,-48
    80005cd0:	f5040513          	addi	a0,s0,-176
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	ab0080e7          	jalr	-1360(ra) # 80004784 <nameiparent>
    80005cdc:	892a                	mv	s2,a0
    80005cde:	c935                	beqz	a0,80005d52 <sys_link+0x10a>
  ilock(dp);
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	2da080e7          	jalr	730(ra) # 80003fba <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ce8:	00092703          	lw	a4,0(s2)
    80005cec:	409c                	lw	a5,0(s1)
    80005cee:	04f71d63          	bne	a4,a5,80005d48 <sys_link+0x100>
    80005cf2:	40d0                	lw	a2,4(s1)
    80005cf4:	fd040593          	addi	a1,s0,-48
    80005cf8:	854a                	mv	a0,s2
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	9ba080e7          	jalr	-1606(ra) # 800046b4 <dirlink>
    80005d02:	04054363          	bltz	a0,80005d48 <sys_link+0x100>
  iunlockput(dp);
    80005d06:	854a                	mv	a0,s2
    80005d08:	ffffe097          	auipc	ra,0xffffe
    80005d0c:	514080e7          	jalr	1300(ra) # 8000421c <iunlockput>
  iput(ip);
    80005d10:	8526                	mv	a0,s1
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	462080e7          	jalr	1122(ra) # 80004174 <iput>
  end_op();
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	cea080e7          	jalr	-790(ra) # 80004a04 <end_op>
  return 0;
    80005d22:	4781                	li	a5,0
    80005d24:	a085                	j	80005d84 <sys_link+0x13c>
    end_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	cde080e7          	jalr	-802(ra) # 80004a04 <end_op>
    return -1;
    80005d2e:	57fd                	li	a5,-1
    80005d30:	a891                	j	80005d84 <sys_link+0x13c>
    iunlockput(ip);
    80005d32:	8526                	mv	a0,s1
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	4e8080e7          	jalr	1256(ra) # 8000421c <iunlockput>
    end_op();
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	cc8080e7          	jalr	-824(ra) # 80004a04 <end_op>
    return -1;
    80005d44:	57fd                	li	a5,-1
    80005d46:	a83d                	j	80005d84 <sys_link+0x13c>
    iunlockput(dp);
    80005d48:	854a                	mv	a0,s2
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	4d2080e7          	jalr	1234(ra) # 8000421c <iunlockput>
  ilock(ip);
    80005d52:	8526                	mv	a0,s1
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	266080e7          	jalr	614(ra) # 80003fba <ilock>
  ip->nlink--;
    80005d5c:	04a4d783          	lhu	a5,74(s1)
    80005d60:	37fd                	addiw	a5,a5,-1
    80005d62:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d66:	8526                	mv	a0,s1
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	186080e7          	jalr	390(ra) # 80003eee <iupdate>
  iunlockput(ip);
    80005d70:	8526                	mv	a0,s1
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	4aa080e7          	jalr	1194(ra) # 8000421c <iunlockput>
  end_op();
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	c8a080e7          	jalr	-886(ra) # 80004a04 <end_op>
  return -1;
    80005d82:	57fd                	li	a5,-1
}
    80005d84:	853e                	mv	a0,a5
    80005d86:	70b2                	ld	ra,296(sp)
    80005d88:	7412                	ld	s0,288(sp)
    80005d8a:	64f2                	ld	s1,280(sp)
    80005d8c:	6952                	ld	s2,272(sp)
    80005d8e:	6155                	addi	sp,sp,304
    80005d90:	8082                	ret

0000000080005d92 <sys_unlink>:
{
    80005d92:	7151                	addi	sp,sp,-240
    80005d94:	f586                	sd	ra,232(sp)
    80005d96:	f1a2                	sd	s0,224(sp)
    80005d98:	eda6                	sd	s1,216(sp)
    80005d9a:	e9ca                	sd	s2,208(sp)
    80005d9c:	e5ce                	sd	s3,200(sp)
    80005d9e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005da0:	08000613          	li	a2,128
    80005da4:	f3040593          	addi	a1,s0,-208
    80005da8:	4501                	li	a0,0
    80005daa:	ffffd097          	auipc	ra,0xffffd
    80005dae:	432080e7          	jalr	1074(ra) # 800031dc <argstr>
    80005db2:	18054163          	bltz	a0,80005f34 <sys_unlink+0x1a2>
  begin_op();
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	bd0080e7          	jalr	-1072(ra) # 80004986 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005dbe:	fb040593          	addi	a1,s0,-80
    80005dc2:	f3040513          	addi	a0,s0,-208
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	9be080e7          	jalr	-1602(ra) # 80004784 <nameiparent>
    80005dce:	84aa                	mv	s1,a0
    80005dd0:	c979                	beqz	a0,80005ea6 <sys_unlink+0x114>
  ilock(dp);
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	1e8080e7          	jalr	488(ra) # 80003fba <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005dda:	00003597          	auipc	a1,0x3
    80005dde:	96e58593          	addi	a1,a1,-1682 # 80008748 <syscalls+0x2d8>
    80005de2:	fb040513          	addi	a0,s0,-80
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	69e080e7          	jalr	1694(ra) # 80004484 <namecmp>
    80005dee:	14050a63          	beqz	a0,80005f42 <sys_unlink+0x1b0>
    80005df2:	00003597          	auipc	a1,0x3
    80005df6:	95e58593          	addi	a1,a1,-1698 # 80008750 <syscalls+0x2e0>
    80005dfa:	fb040513          	addi	a0,s0,-80
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	686080e7          	jalr	1670(ra) # 80004484 <namecmp>
    80005e06:	12050e63          	beqz	a0,80005f42 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e0a:	f2c40613          	addi	a2,s0,-212
    80005e0e:	fb040593          	addi	a1,s0,-80
    80005e12:	8526                	mv	a0,s1
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	68a080e7          	jalr	1674(ra) # 8000449e <dirlookup>
    80005e1c:	892a                	mv	s2,a0
    80005e1e:	12050263          	beqz	a0,80005f42 <sys_unlink+0x1b0>
  ilock(ip);
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	198080e7          	jalr	408(ra) # 80003fba <ilock>
  if(ip->nlink < 1)
    80005e2a:	04a91783          	lh	a5,74(s2)
    80005e2e:	08f05263          	blez	a5,80005eb2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e32:	04491703          	lh	a4,68(s2)
    80005e36:	4785                	li	a5,1
    80005e38:	08f70563          	beq	a4,a5,80005ec2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e3c:	4641                	li	a2,16
    80005e3e:	4581                	li	a1,0
    80005e40:	fc040513          	addi	a0,s0,-64
    80005e44:	ffffb097          	auipc	ra,0xffffb
    80005e48:	032080e7          	jalr	50(ra) # 80000e76 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e4c:	4741                	li	a4,16
    80005e4e:	f2c42683          	lw	a3,-212(s0)
    80005e52:	fc040613          	addi	a2,s0,-64
    80005e56:	4581                	li	a1,0
    80005e58:	8526                	mv	a0,s1
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	50c080e7          	jalr	1292(ra) # 80004366 <writei>
    80005e62:	47c1                	li	a5,16
    80005e64:	0af51563          	bne	a0,a5,80005f0e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005e68:	04491703          	lh	a4,68(s2)
    80005e6c:	4785                	li	a5,1
    80005e6e:	0af70863          	beq	a4,a5,80005f1e <sys_unlink+0x18c>
  iunlockput(dp);
    80005e72:	8526                	mv	a0,s1
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	3a8080e7          	jalr	936(ra) # 8000421c <iunlockput>
  ip->nlink--;
    80005e7c:	04a95783          	lhu	a5,74(s2)
    80005e80:	37fd                	addiw	a5,a5,-1
    80005e82:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e86:	854a                	mv	a0,s2
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	066080e7          	jalr	102(ra) # 80003eee <iupdate>
  iunlockput(ip);
    80005e90:	854a                	mv	a0,s2
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	38a080e7          	jalr	906(ra) # 8000421c <iunlockput>
  end_op();
    80005e9a:	fffff097          	auipc	ra,0xfffff
    80005e9e:	b6a080e7          	jalr	-1174(ra) # 80004a04 <end_op>
  return 0;
    80005ea2:	4501                	li	a0,0
    80005ea4:	a84d                	j	80005f56 <sys_unlink+0x1c4>
    end_op();
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	b5e080e7          	jalr	-1186(ra) # 80004a04 <end_op>
    return -1;
    80005eae:	557d                	li	a0,-1
    80005eb0:	a05d                	j	80005f56 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	8a650513          	addi	a0,a0,-1882 # 80008758 <syscalls+0x2e8>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	686080e7          	jalr	1670(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ec2:	04c92703          	lw	a4,76(s2)
    80005ec6:	02000793          	li	a5,32
    80005eca:	f6e7f9e3          	bgeu	a5,a4,80005e3c <sys_unlink+0xaa>
    80005ece:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ed2:	4741                	li	a4,16
    80005ed4:	86ce                	mv	a3,s3
    80005ed6:	f1840613          	addi	a2,s0,-232
    80005eda:	4581                	li	a1,0
    80005edc:	854a                	mv	a0,s2
    80005ede:	ffffe097          	auipc	ra,0xffffe
    80005ee2:	390080e7          	jalr	912(ra) # 8000426e <readi>
    80005ee6:	47c1                	li	a5,16
    80005ee8:	00f51b63          	bne	a0,a5,80005efe <sys_unlink+0x16c>
    if(de.inum != 0)
    80005eec:	f1845783          	lhu	a5,-232(s0)
    80005ef0:	e7a1                	bnez	a5,80005f38 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ef2:	29c1                	addiw	s3,s3,16
    80005ef4:	04c92783          	lw	a5,76(s2)
    80005ef8:	fcf9ede3          	bltu	s3,a5,80005ed2 <sys_unlink+0x140>
    80005efc:	b781                	j	80005e3c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005efe:	00003517          	auipc	a0,0x3
    80005f02:	87250513          	addi	a0,a0,-1934 # 80008770 <syscalls+0x300>
    80005f06:	ffffa097          	auipc	ra,0xffffa
    80005f0a:	63a080e7          	jalr	1594(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005f0e:	00003517          	auipc	a0,0x3
    80005f12:	87a50513          	addi	a0,a0,-1926 # 80008788 <syscalls+0x318>
    80005f16:	ffffa097          	auipc	ra,0xffffa
    80005f1a:	62a080e7          	jalr	1578(ra) # 80000540 <panic>
    dp->nlink--;
    80005f1e:	04a4d783          	lhu	a5,74(s1)
    80005f22:	37fd                	addiw	a5,a5,-1
    80005f24:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f28:	8526                	mv	a0,s1
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	fc4080e7          	jalr	-60(ra) # 80003eee <iupdate>
    80005f32:	b781                	j	80005e72 <sys_unlink+0xe0>
    return -1;
    80005f34:	557d                	li	a0,-1
    80005f36:	a005                	j	80005f56 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f38:	854a                	mv	a0,s2
    80005f3a:	ffffe097          	auipc	ra,0xffffe
    80005f3e:	2e2080e7          	jalr	738(ra) # 8000421c <iunlockput>
  iunlockput(dp);
    80005f42:	8526                	mv	a0,s1
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	2d8080e7          	jalr	728(ra) # 8000421c <iunlockput>
  end_op();
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	ab8080e7          	jalr	-1352(ra) # 80004a04 <end_op>
  return -1;
    80005f54:	557d                	li	a0,-1
}
    80005f56:	70ae                	ld	ra,232(sp)
    80005f58:	740e                	ld	s0,224(sp)
    80005f5a:	64ee                	ld	s1,216(sp)
    80005f5c:	694e                	ld	s2,208(sp)
    80005f5e:	69ae                	ld	s3,200(sp)
    80005f60:	616d                	addi	sp,sp,240
    80005f62:	8082                	ret

0000000080005f64 <sys_open>:

uint64
sys_open(void)
{
    80005f64:	7131                	addi	sp,sp,-192
    80005f66:	fd06                	sd	ra,184(sp)
    80005f68:	f922                	sd	s0,176(sp)
    80005f6a:	f526                	sd	s1,168(sp)
    80005f6c:	f14a                	sd	s2,160(sp)
    80005f6e:	ed4e                	sd	s3,152(sp)
    80005f70:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005f72:	f4c40593          	addi	a1,s0,-180
    80005f76:	4505                	li	a0,1
    80005f78:	ffffd097          	auipc	ra,0xffffd
    80005f7c:	224080e7          	jalr	548(ra) # 8000319c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f80:	08000613          	li	a2,128
    80005f84:	f5040593          	addi	a1,s0,-176
    80005f88:	4501                	li	a0,0
    80005f8a:	ffffd097          	auipc	ra,0xffffd
    80005f8e:	252080e7          	jalr	594(ra) # 800031dc <argstr>
    80005f92:	87aa                	mv	a5,a0
    return -1;
    80005f94:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f96:	0a07c963          	bltz	a5,80006048 <sys_open+0xe4>

  begin_op();
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	9ec080e7          	jalr	-1556(ra) # 80004986 <begin_op>

  if(omode & O_CREATE){
    80005fa2:	f4c42783          	lw	a5,-180(s0)
    80005fa6:	2007f793          	andi	a5,a5,512
    80005faa:	cfc5                	beqz	a5,80006062 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005fac:	4681                	li	a3,0
    80005fae:	4601                	li	a2,0
    80005fb0:	4589                	li	a1,2
    80005fb2:	f5040513          	addi	a0,s0,-176
    80005fb6:	00000097          	auipc	ra,0x0
    80005fba:	972080e7          	jalr	-1678(ra) # 80005928 <create>
    80005fbe:	84aa                	mv	s1,a0
    if(ip == 0){
    80005fc0:	c959                	beqz	a0,80006056 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005fc2:	04449703          	lh	a4,68(s1)
    80005fc6:	478d                	li	a5,3
    80005fc8:	00f71763          	bne	a4,a5,80005fd6 <sys_open+0x72>
    80005fcc:	0464d703          	lhu	a4,70(s1)
    80005fd0:	47a5                	li	a5,9
    80005fd2:	0ce7ed63          	bltu	a5,a4,800060ac <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	dbc080e7          	jalr	-580(ra) # 80004d92 <filealloc>
    80005fde:	89aa                	mv	s3,a0
    80005fe0:	10050363          	beqz	a0,800060e6 <sys_open+0x182>
    80005fe4:	00000097          	auipc	ra,0x0
    80005fe8:	902080e7          	jalr	-1790(ra) # 800058e6 <fdalloc>
    80005fec:	892a                	mv	s2,a0
    80005fee:	0e054763          	bltz	a0,800060dc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ff2:	04449703          	lh	a4,68(s1)
    80005ff6:	478d                	li	a5,3
    80005ff8:	0cf70563          	beq	a4,a5,800060c2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ffc:	4789                	li	a5,2
    80005ffe:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006002:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006006:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000600a:	f4c42783          	lw	a5,-180(s0)
    8000600e:	0017c713          	xori	a4,a5,1
    80006012:	8b05                	andi	a4,a4,1
    80006014:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006018:	0037f713          	andi	a4,a5,3
    8000601c:	00e03733          	snez	a4,a4
    80006020:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006024:	4007f793          	andi	a5,a5,1024
    80006028:	c791                	beqz	a5,80006034 <sys_open+0xd0>
    8000602a:	04449703          	lh	a4,68(s1)
    8000602e:	4789                	li	a5,2
    80006030:	0af70063          	beq	a4,a5,800060d0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006034:	8526                	mv	a0,s1
    80006036:	ffffe097          	auipc	ra,0xffffe
    8000603a:	046080e7          	jalr	70(ra) # 8000407c <iunlock>
  end_op();
    8000603e:	fffff097          	auipc	ra,0xfffff
    80006042:	9c6080e7          	jalr	-1594(ra) # 80004a04 <end_op>

  return fd;
    80006046:	854a                	mv	a0,s2
}
    80006048:	70ea                	ld	ra,184(sp)
    8000604a:	744a                	ld	s0,176(sp)
    8000604c:	74aa                	ld	s1,168(sp)
    8000604e:	790a                	ld	s2,160(sp)
    80006050:	69ea                	ld	s3,152(sp)
    80006052:	6129                	addi	sp,sp,192
    80006054:	8082                	ret
      end_op();
    80006056:	fffff097          	auipc	ra,0xfffff
    8000605a:	9ae080e7          	jalr	-1618(ra) # 80004a04 <end_op>
      return -1;
    8000605e:	557d                	li	a0,-1
    80006060:	b7e5                	j	80006048 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006062:	f5040513          	addi	a0,s0,-176
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	700080e7          	jalr	1792(ra) # 80004766 <namei>
    8000606e:	84aa                	mv	s1,a0
    80006070:	c905                	beqz	a0,800060a0 <sys_open+0x13c>
    ilock(ip);
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	f48080e7          	jalr	-184(ra) # 80003fba <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000607a:	04449703          	lh	a4,68(s1)
    8000607e:	4785                	li	a5,1
    80006080:	f4f711e3          	bne	a4,a5,80005fc2 <sys_open+0x5e>
    80006084:	f4c42783          	lw	a5,-180(s0)
    80006088:	d7b9                	beqz	a5,80005fd6 <sys_open+0x72>
      iunlockput(ip);
    8000608a:	8526                	mv	a0,s1
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	190080e7          	jalr	400(ra) # 8000421c <iunlockput>
      end_op();
    80006094:	fffff097          	auipc	ra,0xfffff
    80006098:	970080e7          	jalr	-1680(ra) # 80004a04 <end_op>
      return -1;
    8000609c:	557d                	li	a0,-1
    8000609e:	b76d                	j	80006048 <sys_open+0xe4>
      end_op();
    800060a0:	fffff097          	auipc	ra,0xfffff
    800060a4:	964080e7          	jalr	-1692(ra) # 80004a04 <end_op>
      return -1;
    800060a8:	557d                	li	a0,-1
    800060aa:	bf79                	j	80006048 <sys_open+0xe4>
    iunlockput(ip);
    800060ac:	8526                	mv	a0,s1
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	16e080e7          	jalr	366(ra) # 8000421c <iunlockput>
    end_op();
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	94e080e7          	jalr	-1714(ra) # 80004a04 <end_op>
    return -1;
    800060be:	557d                	li	a0,-1
    800060c0:	b761                	j	80006048 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800060c2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800060c6:	04649783          	lh	a5,70(s1)
    800060ca:	02f99223          	sh	a5,36(s3)
    800060ce:	bf25                	j	80006006 <sys_open+0xa2>
    itrunc(ip);
    800060d0:	8526                	mv	a0,s1
    800060d2:	ffffe097          	auipc	ra,0xffffe
    800060d6:	ff6080e7          	jalr	-10(ra) # 800040c8 <itrunc>
    800060da:	bfa9                	j	80006034 <sys_open+0xd0>
      fileclose(f);
    800060dc:	854e                	mv	a0,s3
    800060de:	fffff097          	auipc	ra,0xfffff
    800060e2:	d70080e7          	jalr	-656(ra) # 80004e4e <fileclose>
    iunlockput(ip);
    800060e6:	8526                	mv	a0,s1
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	134080e7          	jalr	308(ra) # 8000421c <iunlockput>
    end_op();
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	914080e7          	jalr	-1772(ra) # 80004a04 <end_op>
    return -1;
    800060f8:	557d                	li	a0,-1
    800060fa:	b7b9                	j	80006048 <sys_open+0xe4>

00000000800060fc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800060fc:	7175                	addi	sp,sp,-144
    800060fe:	e506                	sd	ra,136(sp)
    80006100:	e122                	sd	s0,128(sp)
    80006102:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006104:	fffff097          	auipc	ra,0xfffff
    80006108:	882080e7          	jalr	-1918(ra) # 80004986 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000610c:	08000613          	li	a2,128
    80006110:	f7040593          	addi	a1,s0,-144
    80006114:	4501                	li	a0,0
    80006116:	ffffd097          	auipc	ra,0xffffd
    8000611a:	0c6080e7          	jalr	198(ra) # 800031dc <argstr>
    8000611e:	02054963          	bltz	a0,80006150 <sys_mkdir+0x54>
    80006122:	4681                	li	a3,0
    80006124:	4601                	li	a2,0
    80006126:	4585                	li	a1,1
    80006128:	f7040513          	addi	a0,s0,-144
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	7fc080e7          	jalr	2044(ra) # 80005928 <create>
    80006134:	cd11                	beqz	a0,80006150 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006136:	ffffe097          	auipc	ra,0xffffe
    8000613a:	0e6080e7          	jalr	230(ra) # 8000421c <iunlockput>
  end_op();
    8000613e:	fffff097          	auipc	ra,0xfffff
    80006142:	8c6080e7          	jalr	-1850(ra) # 80004a04 <end_op>
  return 0;
    80006146:	4501                	li	a0,0
}
    80006148:	60aa                	ld	ra,136(sp)
    8000614a:	640a                	ld	s0,128(sp)
    8000614c:	6149                	addi	sp,sp,144
    8000614e:	8082                	ret
    end_op();
    80006150:	fffff097          	auipc	ra,0xfffff
    80006154:	8b4080e7          	jalr	-1868(ra) # 80004a04 <end_op>
    return -1;
    80006158:	557d                	li	a0,-1
    8000615a:	b7fd                	j	80006148 <sys_mkdir+0x4c>

000000008000615c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000615c:	7135                	addi	sp,sp,-160
    8000615e:	ed06                	sd	ra,152(sp)
    80006160:	e922                	sd	s0,144(sp)
    80006162:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006164:	fffff097          	auipc	ra,0xfffff
    80006168:	822080e7          	jalr	-2014(ra) # 80004986 <begin_op>
  argint(1, &major);
    8000616c:	f6c40593          	addi	a1,s0,-148
    80006170:	4505                	li	a0,1
    80006172:	ffffd097          	auipc	ra,0xffffd
    80006176:	02a080e7          	jalr	42(ra) # 8000319c <argint>
  argint(2, &minor);
    8000617a:	f6840593          	addi	a1,s0,-152
    8000617e:	4509                	li	a0,2
    80006180:	ffffd097          	auipc	ra,0xffffd
    80006184:	01c080e7          	jalr	28(ra) # 8000319c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006188:	08000613          	li	a2,128
    8000618c:	f7040593          	addi	a1,s0,-144
    80006190:	4501                	li	a0,0
    80006192:	ffffd097          	auipc	ra,0xffffd
    80006196:	04a080e7          	jalr	74(ra) # 800031dc <argstr>
    8000619a:	02054b63          	bltz	a0,800061d0 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000619e:	f6841683          	lh	a3,-152(s0)
    800061a2:	f6c41603          	lh	a2,-148(s0)
    800061a6:	458d                	li	a1,3
    800061a8:	f7040513          	addi	a0,s0,-144
    800061ac:	fffff097          	auipc	ra,0xfffff
    800061b0:	77c080e7          	jalr	1916(ra) # 80005928 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061b4:	cd11                	beqz	a0,800061d0 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	066080e7          	jalr	102(ra) # 8000421c <iunlockput>
  end_op();
    800061be:	fffff097          	auipc	ra,0xfffff
    800061c2:	846080e7          	jalr	-1978(ra) # 80004a04 <end_op>
  return 0;
    800061c6:	4501                	li	a0,0
}
    800061c8:	60ea                	ld	ra,152(sp)
    800061ca:	644a                	ld	s0,144(sp)
    800061cc:	610d                	addi	sp,sp,160
    800061ce:	8082                	ret
    end_op();
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	834080e7          	jalr	-1996(ra) # 80004a04 <end_op>
    return -1;
    800061d8:	557d                	li	a0,-1
    800061da:	b7fd                	j	800061c8 <sys_mknod+0x6c>

00000000800061dc <sys_chdir>:

uint64
sys_chdir(void)
{
    800061dc:	7135                	addi	sp,sp,-160
    800061de:	ed06                	sd	ra,152(sp)
    800061e0:	e922                	sd	s0,144(sp)
    800061e2:	e526                	sd	s1,136(sp)
    800061e4:	e14a                	sd	s2,128(sp)
    800061e6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	9aa080e7          	jalr	-1622(ra) # 80001b92 <myproc>
    800061f0:	892a                	mv	s2,a0
  
  begin_op();
    800061f2:	ffffe097          	auipc	ra,0xffffe
    800061f6:	794080e7          	jalr	1940(ra) # 80004986 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800061fa:	08000613          	li	a2,128
    800061fe:	f6040593          	addi	a1,s0,-160
    80006202:	4501                	li	a0,0
    80006204:	ffffd097          	auipc	ra,0xffffd
    80006208:	fd8080e7          	jalr	-40(ra) # 800031dc <argstr>
    8000620c:	04054b63          	bltz	a0,80006262 <sys_chdir+0x86>
    80006210:	f6040513          	addi	a0,s0,-160
    80006214:	ffffe097          	auipc	ra,0xffffe
    80006218:	552080e7          	jalr	1362(ra) # 80004766 <namei>
    8000621c:	84aa                	mv	s1,a0
    8000621e:	c131                	beqz	a0,80006262 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006220:	ffffe097          	auipc	ra,0xffffe
    80006224:	d9a080e7          	jalr	-614(ra) # 80003fba <ilock>
  if(ip->type != T_DIR){
    80006228:	04449703          	lh	a4,68(s1)
    8000622c:	4785                	li	a5,1
    8000622e:	04f71063          	bne	a4,a5,8000626e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006232:	8526                	mv	a0,s1
    80006234:	ffffe097          	auipc	ra,0xffffe
    80006238:	e48080e7          	jalr	-440(ra) # 8000407c <iunlock>
  iput(p->cwd);
    8000623c:	15093503          	ld	a0,336(s2)
    80006240:	ffffe097          	auipc	ra,0xffffe
    80006244:	f34080e7          	jalr	-204(ra) # 80004174 <iput>
  end_op();
    80006248:	ffffe097          	auipc	ra,0xffffe
    8000624c:	7bc080e7          	jalr	1980(ra) # 80004a04 <end_op>
  p->cwd = ip;
    80006250:	14993823          	sd	s1,336(s2)
  return 0;
    80006254:	4501                	li	a0,0
}
    80006256:	60ea                	ld	ra,152(sp)
    80006258:	644a                	ld	s0,144(sp)
    8000625a:	64aa                	ld	s1,136(sp)
    8000625c:	690a                	ld	s2,128(sp)
    8000625e:	610d                	addi	sp,sp,160
    80006260:	8082                	ret
    end_op();
    80006262:	ffffe097          	auipc	ra,0xffffe
    80006266:	7a2080e7          	jalr	1954(ra) # 80004a04 <end_op>
    return -1;
    8000626a:	557d                	li	a0,-1
    8000626c:	b7ed                	j	80006256 <sys_chdir+0x7a>
    iunlockput(ip);
    8000626e:	8526                	mv	a0,s1
    80006270:	ffffe097          	auipc	ra,0xffffe
    80006274:	fac080e7          	jalr	-84(ra) # 8000421c <iunlockput>
    end_op();
    80006278:	ffffe097          	auipc	ra,0xffffe
    8000627c:	78c080e7          	jalr	1932(ra) # 80004a04 <end_op>
    return -1;
    80006280:	557d                	li	a0,-1
    80006282:	bfd1                	j	80006256 <sys_chdir+0x7a>

0000000080006284 <sys_exec>:

uint64
sys_exec(void)
{
    80006284:	7145                	addi	sp,sp,-464
    80006286:	e786                	sd	ra,456(sp)
    80006288:	e3a2                	sd	s0,448(sp)
    8000628a:	ff26                	sd	s1,440(sp)
    8000628c:	fb4a                	sd	s2,432(sp)
    8000628e:	f74e                	sd	s3,424(sp)
    80006290:	f352                	sd	s4,416(sp)
    80006292:	ef56                	sd	s5,408(sp)
    80006294:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006296:	e3840593          	addi	a1,s0,-456
    8000629a:	4505                	li	a0,1
    8000629c:	ffffd097          	auipc	ra,0xffffd
    800062a0:	f20080e7          	jalr	-224(ra) # 800031bc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800062a4:	08000613          	li	a2,128
    800062a8:	f4040593          	addi	a1,s0,-192
    800062ac:	4501                	li	a0,0
    800062ae:	ffffd097          	auipc	ra,0xffffd
    800062b2:	f2e080e7          	jalr	-210(ra) # 800031dc <argstr>
    800062b6:	87aa                	mv	a5,a0
    return -1;
    800062b8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800062ba:	0c07c363          	bltz	a5,80006380 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800062be:	10000613          	li	a2,256
    800062c2:	4581                	li	a1,0
    800062c4:	e4040513          	addi	a0,s0,-448
    800062c8:	ffffb097          	auipc	ra,0xffffb
    800062cc:	bae080e7          	jalr	-1106(ra) # 80000e76 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800062d0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800062d4:	89a6                	mv	s3,s1
    800062d6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062d8:	02000a13          	li	s4,32
    800062dc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062e0:	00391513          	slli	a0,s2,0x3
    800062e4:	e3040593          	addi	a1,s0,-464
    800062e8:	e3843783          	ld	a5,-456(s0)
    800062ec:	953e                	add	a0,a0,a5
    800062ee:	ffffd097          	auipc	ra,0xffffd
    800062f2:	e10080e7          	jalr	-496(ra) # 800030fe <fetchaddr>
    800062f6:	02054a63          	bltz	a0,8000632a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800062fa:	e3043783          	ld	a5,-464(s0)
    800062fe:	c3b9                	beqz	a5,80006344 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	976080e7          	jalr	-1674(ra) # 80000c76 <kalloc>
    80006308:	85aa                	mv	a1,a0
    8000630a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000630e:	cd11                	beqz	a0,8000632a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006310:	6605                	lui	a2,0x1
    80006312:	e3043503          	ld	a0,-464(s0)
    80006316:	ffffd097          	auipc	ra,0xffffd
    8000631a:	e3a080e7          	jalr	-454(ra) # 80003150 <fetchstr>
    8000631e:	00054663          	bltz	a0,8000632a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006322:	0905                	addi	s2,s2,1
    80006324:	09a1                	addi	s3,s3,8
    80006326:	fb491be3          	bne	s2,s4,800062dc <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000632a:	f4040913          	addi	s2,s0,-192
    8000632e:	6088                	ld	a0,0(s1)
    80006330:	c539                	beqz	a0,8000637e <sys_exec+0xfa>
    kfree(argv[i]);
    80006332:	ffffb097          	auipc	ra,0xffffb
    80006336:	802080e7          	jalr	-2046(ra) # 80000b34 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000633a:	04a1                	addi	s1,s1,8
    8000633c:	ff2499e3          	bne	s1,s2,8000632e <sys_exec+0xaa>
  return -1;
    80006340:	557d                	li	a0,-1
    80006342:	a83d                	j	80006380 <sys_exec+0xfc>
      argv[i] = 0;
    80006344:	0a8e                	slli	s5,s5,0x3
    80006346:	fc0a8793          	addi	a5,s5,-64
    8000634a:	00878ab3          	add	s5,a5,s0
    8000634e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006352:	e4040593          	addi	a1,s0,-448
    80006356:	f4040513          	addi	a0,s0,-192
    8000635a:	fffff097          	auipc	ra,0xfffff
    8000635e:	16e080e7          	jalr	366(ra) # 800054c8 <exec>
    80006362:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006364:	f4040993          	addi	s3,s0,-192
    80006368:	6088                	ld	a0,0(s1)
    8000636a:	c901                	beqz	a0,8000637a <sys_exec+0xf6>
    kfree(argv[i]);
    8000636c:	ffffa097          	auipc	ra,0xffffa
    80006370:	7c8080e7          	jalr	1992(ra) # 80000b34 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006374:	04a1                	addi	s1,s1,8
    80006376:	ff3499e3          	bne	s1,s3,80006368 <sys_exec+0xe4>
  return ret;
    8000637a:	854a                	mv	a0,s2
    8000637c:	a011                	j	80006380 <sys_exec+0xfc>
  return -1;
    8000637e:	557d                	li	a0,-1
}
    80006380:	60be                	ld	ra,456(sp)
    80006382:	641e                	ld	s0,448(sp)
    80006384:	74fa                	ld	s1,440(sp)
    80006386:	795a                	ld	s2,432(sp)
    80006388:	79ba                	ld	s3,424(sp)
    8000638a:	7a1a                	ld	s4,416(sp)
    8000638c:	6afa                	ld	s5,408(sp)
    8000638e:	6179                	addi	sp,sp,464
    80006390:	8082                	ret

0000000080006392 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006392:	7139                	addi	sp,sp,-64
    80006394:	fc06                	sd	ra,56(sp)
    80006396:	f822                	sd	s0,48(sp)
    80006398:	f426                	sd	s1,40(sp)
    8000639a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000639c:	ffffb097          	auipc	ra,0xffffb
    800063a0:	7f6080e7          	jalr	2038(ra) # 80001b92 <myproc>
    800063a4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800063a6:	fd840593          	addi	a1,s0,-40
    800063aa:	4501                	li	a0,0
    800063ac:	ffffd097          	auipc	ra,0xffffd
    800063b0:	e10080e7          	jalr	-496(ra) # 800031bc <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800063b4:	fc840593          	addi	a1,s0,-56
    800063b8:	fd040513          	addi	a0,s0,-48
    800063bc:	fffff097          	auipc	ra,0xfffff
    800063c0:	dc2080e7          	jalr	-574(ra) # 8000517e <pipealloc>
    return -1;
    800063c4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063c6:	0c054463          	bltz	a0,8000648e <sys_pipe+0xfc>
  fd0 = -1;
    800063ca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063ce:	fd043503          	ld	a0,-48(s0)
    800063d2:	fffff097          	auipc	ra,0xfffff
    800063d6:	514080e7          	jalr	1300(ra) # 800058e6 <fdalloc>
    800063da:	fca42223          	sw	a0,-60(s0)
    800063de:	08054b63          	bltz	a0,80006474 <sys_pipe+0xe2>
    800063e2:	fc843503          	ld	a0,-56(s0)
    800063e6:	fffff097          	auipc	ra,0xfffff
    800063ea:	500080e7          	jalr	1280(ra) # 800058e6 <fdalloc>
    800063ee:	fca42023          	sw	a0,-64(s0)
    800063f2:	06054863          	bltz	a0,80006462 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063f6:	4691                	li	a3,4
    800063f8:	fc440613          	addi	a2,s0,-60
    800063fc:	fd843583          	ld	a1,-40(s0)
    80006400:	68a8                	ld	a0,80(s1)
    80006402:	ffffb097          	auipc	ra,0xffffb
    80006406:	418080e7          	jalr	1048(ra) # 8000181a <copyout>
    8000640a:	02054063          	bltz	a0,8000642a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000640e:	4691                	li	a3,4
    80006410:	fc040613          	addi	a2,s0,-64
    80006414:	fd843583          	ld	a1,-40(s0)
    80006418:	0591                	addi	a1,a1,4
    8000641a:	68a8                	ld	a0,80(s1)
    8000641c:	ffffb097          	auipc	ra,0xffffb
    80006420:	3fe080e7          	jalr	1022(ra) # 8000181a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006424:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006426:	06055463          	bgez	a0,8000648e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000642a:	fc442783          	lw	a5,-60(s0)
    8000642e:	07e9                	addi	a5,a5,26
    80006430:	078e                	slli	a5,a5,0x3
    80006432:	97a6                	add	a5,a5,s1
    80006434:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006438:	fc042783          	lw	a5,-64(s0)
    8000643c:	07e9                	addi	a5,a5,26
    8000643e:	078e                	slli	a5,a5,0x3
    80006440:	94be                	add	s1,s1,a5
    80006442:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006446:	fd043503          	ld	a0,-48(s0)
    8000644a:	fffff097          	auipc	ra,0xfffff
    8000644e:	a04080e7          	jalr	-1532(ra) # 80004e4e <fileclose>
    fileclose(wf);
    80006452:	fc843503          	ld	a0,-56(s0)
    80006456:	fffff097          	auipc	ra,0xfffff
    8000645a:	9f8080e7          	jalr	-1544(ra) # 80004e4e <fileclose>
    return -1;
    8000645e:	57fd                	li	a5,-1
    80006460:	a03d                	j	8000648e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006462:	fc442783          	lw	a5,-60(s0)
    80006466:	0007c763          	bltz	a5,80006474 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000646a:	07e9                	addi	a5,a5,26
    8000646c:	078e                	slli	a5,a5,0x3
    8000646e:	97a6                	add	a5,a5,s1
    80006470:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006474:	fd043503          	ld	a0,-48(s0)
    80006478:	fffff097          	auipc	ra,0xfffff
    8000647c:	9d6080e7          	jalr	-1578(ra) # 80004e4e <fileclose>
    fileclose(wf);
    80006480:	fc843503          	ld	a0,-56(s0)
    80006484:	fffff097          	auipc	ra,0xfffff
    80006488:	9ca080e7          	jalr	-1590(ra) # 80004e4e <fileclose>
    return -1;
    8000648c:	57fd                	li	a5,-1
}
    8000648e:	853e                	mv	a0,a5
    80006490:	70e2                	ld	ra,56(sp)
    80006492:	7442                	ld	s0,48(sp)
    80006494:	74a2                	ld	s1,40(sp)
    80006496:	6121                	addi	sp,sp,64
    80006498:	8082                	ret
    8000649a:	0000                	unimp
    8000649c:	0000                	unimp
	...

00000000800064a0 <kernelvec>:
    800064a0:	7111                	addi	sp,sp,-256
    800064a2:	e006                	sd	ra,0(sp)
    800064a4:	e40a                	sd	sp,8(sp)
    800064a6:	e80e                	sd	gp,16(sp)
    800064a8:	ec12                	sd	tp,24(sp)
    800064aa:	f016                	sd	t0,32(sp)
    800064ac:	f41a                	sd	t1,40(sp)
    800064ae:	f81e                	sd	t2,48(sp)
    800064b0:	fc22                	sd	s0,56(sp)
    800064b2:	e0a6                	sd	s1,64(sp)
    800064b4:	e4aa                	sd	a0,72(sp)
    800064b6:	e8ae                	sd	a1,80(sp)
    800064b8:	ecb2                	sd	a2,88(sp)
    800064ba:	f0b6                	sd	a3,96(sp)
    800064bc:	f4ba                	sd	a4,104(sp)
    800064be:	f8be                	sd	a5,112(sp)
    800064c0:	fcc2                	sd	a6,120(sp)
    800064c2:	e146                	sd	a7,128(sp)
    800064c4:	e54a                	sd	s2,136(sp)
    800064c6:	e94e                	sd	s3,144(sp)
    800064c8:	ed52                	sd	s4,152(sp)
    800064ca:	f156                	sd	s5,160(sp)
    800064cc:	f55a                	sd	s6,168(sp)
    800064ce:	f95e                	sd	s7,176(sp)
    800064d0:	fd62                	sd	s8,184(sp)
    800064d2:	e1e6                	sd	s9,192(sp)
    800064d4:	e5ea                	sd	s10,200(sp)
    800064d6:	e9ee                	sd	s11,208(sp)
    800064d8:	edf2                	sd	t3,216(sp)
    800064da:	f1f6                	sd	t4,224(sp)
    800064dc:	f5fa                	sd	t5,232(sp)
    800064de:	f9fe                	sd	t6,240(sp)
    800064e0:	aebfc0ef          	jal	ra,80002fca <kerneltrap>
    800064e4:	6082                	ld	ra,0(sp)
    800064e6:	6122                	ld	sp,8(sp)
    800064e8:	61c2                	ld	gp,16(sp)
    800064ea:	7282                	ld	t0,32(sp)
    800064ec:	7322                	ld	t1,40(sp)
    800064ee:	73c2                	ld	t2,48(sp)
    800064f0:	7462                	ld	s0,56(sp)
    800064f2:	6486                	ld	s1,64(sp)
    800064f4:	6526                	ld	a0,72(sp)
    800064f6:	65c6                	ld	a1,80(sp)
    800064f8:	6666                	ld	a2,88(sp)
    800064fa:	7686                	ld	a3,96(sp)
    800064fc:	7726                	ld	a4,104(sp)
    800064fe:	77c6                	ld	a5,112(sp)
    80006500:	7866                	ld	a6,120(sp)
    80006502:	688a                	ld	a7,128(sp)
    80006504:	692a                	ld	s2,136(sp)
    80006506:	69ca                	ld	s3,144(sp)
    80006508:	6a6a                	ld	s4,152(sp)
    8000650a:	7a8a                	ld	s5,160(sp)
    8000650c:	7b2a                	ld	s6,168(sp)
    8000650e:	7bca                	ld	s7,176(sp)
    80006510:	7c6a                	ld	s8,184(sp)
    80006512:	6c8e                	ld	s9,192(sp)
    80006514:	6d2e                	ld	s10,200(sp)
    80006516:	6dce                	ld	s11,208(sp)
    80006518:	6e6e                	ld	t3,216(sp)
    8000651a:	7e8e                	ld	t4,224(sp)
    8000651c:	7f2e                	ld	t5,232(sp)
    8000651e:	7fce                	ld	t6,240(sp)
    80006520:	6111                	addi	sp,sp,256
    80006522:	10200073          	sret
    80006526:	00000013          	nop
    8000652a:	00000013          	nop
    8000652e:	0001                	nop

0000000080006530 <timervec>:
    80006530:	34051573          	csrrw	a0,mscratch,a0
    80006534:	e10c                	sd	a1,0(a0)
    80006536:	e510                	sd	a2,8(a0)
    80006538:	e914                	sd	a3,16(a0)
    8000653a:	6d0c                	ld	a1,24(a0)
    8000653c:	7110                	ld	a2,32(a0)
    8000653e:	6194                	ld	a3,0(a1)
    80006540:	96b2                	add	a3,a3,a2
    80006542:	e194                	sd	a3,0(a1)
    80006544:	4589                	li	a1,2
    80006546:	14459073          	csrw	sip,a1
    8000654a:	6914                	ld	a3,16(a0)
    8000654c:	6510                	ld	a2,8(a0)
    8000654e:	610c                	ld	a1,0(a0)
    80006550:	34051573          	csrrw	a0,mscratch,a0
    80006554:	30200073          	mret
	...

000000008000655a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000655a:	1141                	addi	sp,sp,-16
    8000655c:	e422                	sd	s0,8(sp)
    8000655e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006560:	0c0007b7          	lui	a5,0xc000
    80006564:	4705                	li	a4,1
    80006566:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006568:	c3d8                	sw	a4,4(a5)
}
    8000656a:	6422                	ld	s0,8(sp)
    8000656c:	0141                	addi	sp,sp,16
    8000656e:	8082                	ret

0000000080006570 <plicinithart>:

void
plicinithart(void)
{
    80006570:	1141                	addi	sp,sp,-16
    80006572:	e406                	sd	ra,8(sp)
    80006574:	e022                	sd	s0,0(sp)
    80006576:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006578:	ffffb097          	auipc	ra,0xffffb
    8000657c:	5ee080e7          	jalr	1518(ra) # 80001b66 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006580:	0085171b          	slliw	a4,a0,0x8
    80006584:	0c0027b7          	lui	a5,0xc002
    80006588:	97ba                	add	a5,a5,a4
    8000658a:	40200713          	li	a4,1026
    8000658e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006592:	00d5151b          	slliw	a0,a0,0xd
    80006596:	0c2017b7          	lui	a5,0xc201
    8000659a:	97aa                	add	a5,a5,a0
    8000659c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800065a0:	60a2                	ld	ra,8(sp)
    800065a2:	6402                	ld	s0,0(sp)
    800065a4:	0141                	addi	sp,sp,16
    800065a6:	8082                	ret

00000000800065a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800065a8:	1141                	addi	sp,sp,-16
    800065aa:	e406                	sd	ra,8(sp)
    800065ac:	e022                	sd	s0,0(sp)
    800065ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065b0:	ffffb097          	auipc	ra,0xffffb
    800065b4:	5b6080e7          	jalr	1462(ra) # 80001b66 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800065b8:	00d5151b          	slliw	a0,a0,0xd
    800065bc:	0c2017b7          	lui	a5,0xc201
    800065c0:	97aa                	add	a5,a5,a0
  return irq;
}
    800065c2:	43c8                	lw	a0,4(a5)
    800065c4:	60a2                	ld	ra,8(sp)
    800065c6:	6402                	ld	s0,0(sp)
    800065c8:	0141                	addi	sp,sp,16
    800065ca:	8082                	ret

00000000800065cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800065cc:	1101                	addi	sp,sp,-32
    800065ce:	ec06                	sd	ra,24(sp)
    800065d0:	e822                	sd	s0,16(sp)
    800065d2:	e426                	sd	s1,8(sp)
    800065d4:	1000                	addi	s0,sp,32
    800065d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800065d8:	ffffb097          	auipc	ra,0xffffb
    800065dc:	58e080e7          	jalr	1422(ra) # 80001b66 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800065e0:	00d5151b          	slliw	a0,a0,0xd
    800065e4:	0c2017b7          	lui	a5,0xc201
    800065e8:	97aa                	add	a5,a5,a0
    800065ea:	c3c4                	sw	s1,4(a5)
}
    800065ec:	60e2                	ld	ra,24(sp)
    800065ee:	6442                	ld	s0,16(sp)
    800065f0:	64a2                	ld	s1,8(sp)
    800065f2:	6105                	addi	sp,sp,32
    800065f4:	8082                	ret

00000000800065f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800065f6:	1141                	addi	sp,sp,-16
    800065f8:	e406                	sd	ra,8(sp)
    800065fa:	e022                	sd	s0,0(sp)
    800065fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800065fe:	479d                	li	a5,7
    80006600:	04a7cc63          	blt	a5,a0,80006658 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006604:	0023d797          	auipc	a5,0x23d
    80006608:	e9478793          	addi	a5,a5,-364 # 80243498 <disk>
    8000660c:	97aa                	add	a5,a5,a0
    8000660e:	0187c783          	lbu	a5,24(a5)
    80006612:	ebb9                	bnez	a5,80006668 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006614:	00451693          	slli	a3,a0,0x4
    80006618:	0023d797          	auipc	a5,0x23d
    8000661c:	e8078793          	addi	a5,a5,-384 # 80243498 <disk>
    80006620:	6398                	ld	a4,0(a5)
    80006622:	9736                	add	a4,a4,a3
    80006624:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006628:	6398                	ld	a4,0(a5)
    8000662a:	9736                	add	a4,a4,a3
    8000662c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006630:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006634:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006638:	97aa                	add	a5,a5,a0
    8000663a:	4705                	li	a4,1
    8000663c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006640:	0023d517          	auipc	a0,0x23d
    80006644:	e7050513          	addi	a0,a0,-400 # 802434b0 <disk+0x18>
    80006648:	ffffc097          	auipc	ra,0xffffc
    8000664c:	d6c080e7          	jalr	-660(ra) # 800023b4 <wakeup>
}
    80006650:	60a2                	ld	ra,8(sp)
    80006652:	6402                	ld	s0,0(sp)
    80006654:	0141                	addi	sp,sp,16
    80006656:	8082                	ret
    panic("free_desc 1");
    80006658:	00002517          	auipc	a0,0x2
    8000665c:	14050513          	addi	a0,a0,320 # 80008798 <syscalls+0x328>
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	ee0080e7          	jalr	-288(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006668:	00002517          	auipc	a0,0x2
    8000666c:	14050513          	addi	a0,a0,320 # 800087a8 <syscalls+0x338>
    80006670:	ffffa097          	auipc	ra,0xffffa
    80006674:	ed0080e7          	jalr	-304(ra) # 80000540 <panic>

0000000080006678 <virtio_disk_init>:
{
    80006678:	1101                	addi	sp,sp,-32
    8000667a:	ec06                	sd	ra,24(sp)
    8000667c:	e822                	sd	s0,16(sp)
    8000667e:	e426                	sd	s1,8(sp)
    80006680:	e04a                	sd	s2,0(sp)
    80006682:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006684:	00002597          	auipc	a1,0x2
    80006688:	13458593          	addi	a1,a1,308 # 800087b8 <syscalls+0x348>
    8000668c:	0023d517          	auipc	a0,0x23d
    80006690:	f3450513          	addi	a0,a0,-204 # 802435c0 <disk+0x128>
    80006694:	ffffa097          	auipc	ra,0xffffa
    80006698:	656080e7          	jalr	1622(ra) # 80000cea <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000669c:	100017b7          	lui	a5,0x10001
    800066a0:	4398                	lw	a4,0(a5)
    800066a2:	2701                	sext.w	a4,a4
    800066a4:	747277b7          	lui	a5,0x74727
    800066a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066ac:	14f71b63          	bne	a4,a5,80006802 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800066b0:	100017b7          	lui	a5,0x10001
    800066b4:	43dc                	lw	a5,4(a5)
    800066b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066b8:	4709                	li	a4,2
    800066ba:	14e79463          	bne	a5,a4,80006802 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066be:	100017b7          	lui	a5,0x10001
    800066c2:	479c                	lw	a5,8(a5)
    800066c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800066c6:	12e79e63          	bne	a5,a4,80006802 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800066ca:	100017b7          	lui	a5,0x10001
    800066ce:	47d8                	lw	a4,12(a5)
    800066d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066d2:	554d47b7          	lui	a5,0x554d4
    800066d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800066da:	12f71463          	bne	a4,a5,80006802 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066de:	100017b7          	lui	a5,0x10001
    800066e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066e6:	4705                	li	a4,1
    800066e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066ea:	470d                	li	a4,3
    800066ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800066ee:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800066f0:	c7ffe6b7          	lui	a3,0xc7ffe
    800066f4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbb187>
    800066f8:	8f75                	and	a4,a4,a3
    800066fa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066fc:	472d                	li	a4,11
    800066fe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006700:	5bbc                	lw	a5,112(a5)
    80006702:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006706:	8ba1                	andi	a5,a5,8
    80006708:	10078563          	beqz	a5,80006812 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000670c:	100017b7          	lui	a5,0x10001
    80006710:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006714:	43fc                	lw	a5,68(a5)
    80006716:	2781                	sext.w	a5,a5
    80006718:	10079563          	bnez	a5,80006822 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000671c:	100017b7          	lui	a5,0x10001
    80006720:	5bdc                	lw	a5,52(a5)
    80006722:	2781                	sext.w	a5,a5
  if(max == 0)
    80006724:	10078763          	beqz	a5,80006832 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006728:	471d                	li	a4,7
    8000672a:	10f77c63          	bgeu	a4,a5,80006842 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000672e:	ffffa097          	auipc	ra,0xffffa
    80006732:	548080e7          	jalr	1352(ra) # 80000c76 <kalloc>
    80006736:	0023d497          	auipc	s1,0x23d
    8000673a:	d6248493          	addi	s1,s1,-670 # 80243498 <disk>
    8000673e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006740:	ffffa097          	auipc	ra,0xffffa
    80006744:	536080e7          	jalr	1334(ra) # 80000c76 <kalloc>
    80006748:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000674a:	ffffa097          	auipc	ra,0xffffa
    8000674e:	52c080e7          	jalr	1324(ra) # 80000c76 <kalloc>
    80006752:	87aa                	mv	a5,a0
    80006754:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006756:	6088                	ld	a0,0(s1)
    80006758:	cd6d                	beqz	a0,80006852 <virtio_disk_init+0x1da>
    8000675a:	0023d717          	auipc	a4,0x23d
    8000675e:	d4673703          	ld	a4,-698(a4) # 802434a0 <disk+0x8>
    80006762:	cb65                	beqz	a4,80006852 <virtio_disk_init+0x1da>
    80006764:	c7fd                	beqz	a5,80006852 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006766:	6605                	lui	a2,0x1
    80006768:	4581                	li	a1,0
    8000676a:	ffffa097          	auipc	ra,0xffffa
    8000676e:	70c080e7          	jalr	1804(ra) # 80000e76 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006772:	0023d497          	auipc	s1,0x23d
    80006776:	d2648493          	addi	s1,s1,-730 # 80243498 <disk>
    8000677a:	6605                	lui	a2,0x1
    8000677c:	4581                	li	a1,0
    8000677e:	6488                	ld	a0,8(s1)
    80006780:	ffffa097          	auipc	ra,0xffffa
    80006784:	6f6080e7          	jalr	1782(ra) # 80000e76 <memset>
  memset(disk.used, 0, PGSIZE);
    80006788:	6605                	lui	a2,0x1
    8000678a:	4581                	li	a1,0
    8000678c:	6888                	ld	a0,16(s1)
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	6e8080e7          	jalr	1768(ra) # 80000e76 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006796:	100017b7          	lui	a5,0x10001
    8000679a:	4721                	li	a4,8
    8000679c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000679e:	4098                	lw	a4,0(s1)
    800067a0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800067a4:	40d8                	lw	a4,4(s1)
    800067a6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800067aa:	6498                	ld	a4,8(s1)
    800067ac:	0007069b          	sext.w	a3,a4
    800067b0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800067b4:	9701                	srai	a4,a4,0x20
    800067b6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800067ba:	6898                	ld	a4,16(s1)
    800067bc:	0007069b          	sext.w	a3,a4
    800067c0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800067c4:	9701                	srai	a4,a4,0x20
    800067c6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800067ca:	4705                	li	a4,1
    800067cc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800067ce:	00e48c23          	sb	a4,24(s1)
    800067d2:	00e48ca3          	sb	a4,25(s1)
    800067d6:	00e48d23          	sb	a4,26(s1)
    800067da:	00e48da3          	sb	a4,27(s1)
    800067de:	00e48e23          	sb	a4,28(s1)
    800067e2:	00e48ea3          	sb	a4,29(s1)
    800067e6:	00e48f23          	sb	a4,30(s1)
    800067ea:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800067ee:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800067f2:	0727a823          	sw	s2,112(a5)
}
    800067f6:	60e2                	ld	ra,24(sp)
    800067f8:	6442                	ld	s0,16(sp)
    800067fa:	64a2                	ld	s1,8(sp)
    800067fc:	6902                	ld	s2,0(sp)
    800067fe:	6105                	addi	sp,sp,32
    80006800:	8082                	ret
    panic("could not find virtio disk");
    80006802:	00002517          	auipc	a0,0x2
    80006806:	fc650513          	addi	a0,a0,-58 # 800087c8 <syscalls+0x358>
    8000680a:	ffffa097          	auipc	ra,0xffffa
    8000680e:	d36080e7          	jalr	-714(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006812:	00002517          	auipc	a0,0x2
    80006816:	fd650513          	addi	a0,a0,-42 # 800087e8 <syscalls+0x378>
    8000681a:	ffffa097          	auipc	ra,0xffffa
    8000681e:	d26080e7          	jalr	-730(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006822:	00002517          	auipc	a0,0x2
    80006826:	fe650513          	addi	a0,a0,-26 # 80008808 <syscalls+0x398>
    8000682a:	ffffa097          	auipc	ra,0xffffa
    8000682e:	d16080e7          	jalr	-746(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006832:	00002517          	auipc	a0,0x2
    80006836:	ff650513          	addi	a0,a0,-10 # 80008828 <syscalls+0x3b8>
    8000683a:	ffffa097          	auipc	ra,0xffffa
    8000683e:	d06080e7          	jalr	-762(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006842:	00002517          	auipc	a0,0x2
    80006846:	00650513          	addi	a0,a0,6 # 80008848 <syscalls+0x3d8>
    8000684a:	ffffa097          	auipc	ra,0xffffa
    8000684e:	cf6080e7          	jalr	-778(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006852:	00002517          	auipc	a0,0x2
    80006856:	01650513          	addi	a0,a0,22 # 80008868 <syscalls+0x3f8>
    8000685a:	ffffa097          	auipc	ra,0xffffa
    8000685e:	ce6080e7          	jalr	-794(ra) # 80000540 <panic>

0000000080006862 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006862:	7119                	addi	sp,sp,-128
    80006864:	fc86                	sd	ra,120(sp)
    80006866:	f8a2                	sd	s0,112(sp)
    80006868:	f4a6                	sd	s1,104(sp)
    8000686a:	f0ca                	sd	s2,96(sp)
    8000686c:	ecce                	sd	s3,88(sp)
    8000686e:	e8d2                	sd	s4,80(sp)
    80006870:	e4d6                	sd	s5,72(sp)
    80006872:	e0da                	sd	s6,64(sp)
    80006874:	fc5e                	sd	s7,56(sp)
    80006876:	f862                	sd	s8,48(sp)
    80006878:	f466                	sd	s9,40(sp)
    8000687a:	f06a                	sd	s10,32(sp)
    8000687c:	ec6e                	sd	s11,24(sp)
    8000687e:	0100                	addi	s0,sp,128
    80006880:	8aaa                	mv	s5,a0
    80006882:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006884:	00c52d03          	lw	s10,12(a0)
    80006888:	001d1d1b          	slliw	s10,s10,0x1
    8000688c:	1d02                	slli	s10,s10,0x20
    8000688e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006892:	0023d517          	auipc	a0,0x23d
    80006896:	d2e50513          	addi	a0,a0,-722 # 802435c0 <disk+0x128>
    8000689a:	ffffa097          	auipc	ra,0xffffa
    8000689e:	4e0080e7          	jalr	1248(ra) # 80000d7a <acquire>
  for(int i = 0; i < 3; i++){
    800068a2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800068a4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800068a6:	0023db97          	auipc	s7,0x23d
    800068aa:	bf2b8b93          	addi	s7,s7,-1038 # 80243498 <disk>
  for(int i = 0; i < 3; i++){
    800068ae:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068b0:	0023dc97          	auipc	s9,0x23d
    800068b4:	d10c8c93          	addi	s9,s9,-752 # 802435c0 <disk+0x128>
    800068b8:	a08d                	j	8000691a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800068ba:	00fb8733          	add	a4,s7,a5
    800068be:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800068c2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800068c4:	0207c563          	bltz	a5,800068ee <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800068c8:	2905                	addiw	s2,s2,1
    800068ca:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800068cc:	05690c63          	beq	s2,s6,80006924 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800068d0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800068d2:	0023d717          	auipc	a4,0x23d
    800068d6:	bc670713          	addi	a4,a4,-1082 # 80243498 <disk>
    800068da:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800068dc:	01874683          	lbu	a3,24(a4)
    800068e0:	fee9                	bnez	a3,800068ba <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800068e2:	2785                	addiw	a5,a5,1
    800068e4:	0705                	addi	a4,a4,1
    800068e6:	fe979be3          	bne	a5,s1,800068dc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800068ea:	57fd                	li	a5,-1
    800068ec:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800068ee:	01205d63          	blez	s2,80006908 <virtio_disk_rw+0xa6>
    800068f2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800068f4:	000a2503          	lw	a0,0(s4)
    800068f8:	00000097          	auipc	ra,0x0
    800068fc:	cfe080e7          	jalr	-770(ra) # 800065f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006900:	2d85                	addiw	s11,s11,1
    80006902:	0a11                	addi	s4,s4,4
    80006904:	ff2d98e3          	bne	s11,s2,800068f4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006908:	85e6                	mv	a1,s9
    8000690a:	0023d517          	auipc	a0,0x23d
    8000690e:	ba650513          	addi	a0,a0,-1114 # 802434b0 <disk+0x18>
    80006912:	ffffc097          	auipc	ra,0xffffc
    80006916:	a3e080e7          	jalr	-1474(ra) # 80002350 <sleep>
  for(int i = 0; i < 3; i++){
    8000691a:	f8040a13          	addi	s4,s0,-128
{
    8000691e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006920:	894e                	mv	s2,s3
    80006922:	b77d                	j	800068d0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006924:	f8042503          	lw	a0,-128(s0)
    80006928:	00a50713          	addi	a4,a0,10
    8000692c:	0712                	slli	a4,a4,0x4

  if(write)
    8000692e:	0023d797          	auipc	a5,0x23d
    80006932:	b6a78793          	addi	a5,a5,-1174 # 80243498 <disk>
    80006936:	00e786b3          	add	a3,a5,a4
    8000693a:	01803633          	snez	a2,s8
    8000693e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006940:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006944:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006948:	f6070613          	addi	a2,a4,-160
    8000694c:	6394                	ld	a3,0(a5)
    8000694e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006950:	00870593          	addi	a1,a4,8
    80006954:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006956:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006958:	0007b803          	ld	a6,0(a5)
    8000695c:	9642                	add	a2,a2,a6
    8000695e:	46c1                	li	a3,16
    80006960:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006962:	4585                	li	a1,1
    80006964:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006968:	f8442683          	lw	a3,-124(s0)
    8000696c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006970:	0692                	slli	a3,a3,0x4
    80006972:	9836                	add	a6,a6,a3
    80006974:	058a8613          	addi	a2,s5,88
    80006978:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000697c:	0007b803          	ld	a6,0(a5)
    80006980:	96c2                	add	a3,a3,a6
    80006982:	40000613          	li	a2,1024
    80006986:	c690                	sw	a2,8(a3)
  if(write)
    80006988:	001c3613          	seqz	a2,s8
    8000698c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006990:	00166613          	ori	a2,a2,1
    80006994:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006998:	f8842603          	lw	a2,-120(s0)
    8000699c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069a0:	00250693          	addi	a3,a0,2
    800069a4:	0692                	slli	a3,a3,0x4
    800069a6:	96be                	add	a3,a3,a5
    800069a8:	58fd                	li	a7,-1
    800069aa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069ae:	0612                	slli	a2,a2,0x4
    800069b0:	9832                	add	a6,a6,a2
    800069b2:	f9070713          	addi	a4,a4,-112
    800069b6:	973e                	add	a4,a4,a5
    800069b8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800069bc:	6398                	ld	a4,0(a5)
    800069be:	9732                	add	a4,a4,a2
    800069c0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800069c2:	4609                	li	a2,2
    800069c4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800069c8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800069cc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800069d0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800069d4:	6794                	ld	a3,8(a5)
    800069d6:	0026d703          	lhu	a4,2(a3)
    800069da:	8b1d                	andi	a4,a4,7
    800069dc:	0706                	slli	a4,a4,0x1
    800069de:	96ba                	add	a3,a3,a4
    800069e0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800069e4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800069e8:	6798                	ld	a4,8(a5)
    800069ea:	00275783          	lhu	a5,2(a4)
    800069ee:	2785                	addiw	a5,a5,1
    800069f0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800069f4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800069f8:	100017b7          	lui	a5,0x10001
    800069fc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a00:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006a04:	0023d917          	auipc	s2,0x23d
    80006a08:	bbc90913          	addi	s2,s2,-1092 # 802435c0 <disk+0x128>
  while(b->disk == 1) {
    80006a0c:	4485                	li	s1,1
    80006a0e:	00b79c63          	bne	a5,a1,80006a26 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006a12:	85ca                	mv	a1,s2
    80006a14:	8556                	mv	a0,s5
    80006a16:	ffffc097          	auipc	ra,0xffffc
    80006a1a:	93a080e7          	jalr	-1734(ra) # 80002350 <sleep>
  while(b->disk == 1) {
    80006a1e:	004aa783          	lw	a5,4(s5)
    80006a22:	fe9788e3          	beq	a5,s1,80006a12 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006a26:	f8042903          	lw	s2,-128(s0)
    80006a2a:	00290713          	addi	a4,s2,2
    80006a2e:	0712                	slli	a4,a4,0x4
    80006a30:	0023d797          	auipc	a5,0x23d
    80006a34:	a6878793          	addi	a5,a5,-1432 # 80243498 <disk>
    80006a38:	97ba                	add	a5,a5,a4
    80006a3a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006a3e:	0023d997          	auipc	s3,0x23d
    80006a42:	a5a98993          	addi	s3,s3,-1446 # 80243498 <disk>
    80006a46:	00491713          	slli	a4,s2,0x4
    80006a4a:	0009b783          	ld	a5,0(s3)
    80006a4e:	97ba                	add	a5,a5,a4
    80006a50:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a54:	854a                	mv	a0,s2
    80006a56:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a5a:	00000097          	auipc	ra,0x0
    80006a5e:	b9c080e7          	jalr	-1124(ra) # 800065f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a62:	8885                	andi	s1,s1,1
    80006a64:	f0ed                	bnez	s1,80006a46 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a66:	0023d517          	auipc	a0,0x23d
    80006a6a:	b5a50513          	addi	a0,a0,-1190 # 802435c0 <disk+0x128>
    80006a6e:	ffffa097          	auipc	ra,0xffffa
    80006a72:	3c0080e7          	jalr	960(ra) # 80000e2e <release>
}
    80006a76:	70e6                	ld	ra,120(sp)
    80006a78:	7446                	ld	s0,112(sp)
    80006a7a:	74a6                	ld	s1,104(sp)
    80006a7c:	7906                	ld	s2,96(sp)
    80006a7e:	69e6                	ld	s3,88(sp)
    80006a80:	6a46                	ld	s4,80(sp)
    80006a82:	6aa6                	ld	s5,72(sp)
    80006a84:	6b06                	ld	s6,64(sp)
    80006a86:	7be2                	ld	s7,56(sp)
    80006a88:	7c42                	ld	s8,48(sp)
    80006a8a:	7ca2                	ld	s9,40(sp)
    80006a8c:	7d02                	ld	s10,32(sp)
    80006a8e:	6de2                	ld	s11,24(sp)
    80006a90:	6109                	addi	sp,sp,128
    80006a92:	8082                	ret

0000000080006a94 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a94:	1101                	addi	sp,sp,-32
    80006a96:	ec06                	sd	ra,24(sp)
    80006a98:	e822                	sd	s0,16(sp)
    80006a9a:	e426                	sd	s1,8(sp)
    80006a9c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a9e:	0023d497          	auipc	s1,0x23d
    80006aa2:	9fa48493          	addi	s1,s1,-1542 # 80243498 <disk>
    80006aa6:	0023d517          	auipc	a0,0x23d
    80006aaa:	b1a50513          	addi	a0,a0,-1254 # 802435c0 <disk+0x128>
    80006aae:	ffffa097          	auipc	ra,0xffffa
    80006ab2:	2cc080e7          	jalr	716(ra) # 80000d7a <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006ab6:	10001737          	lui	a4,0x10001
    80006aba:	533c                	lw	a5,96(a4)
    80006abc:	8b8d                	andi	a5,a5,3
    80006abe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ac0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ac4:	689c                	ld	a5,16(s1)
    80006ac6:	0204d703          	lhu	a4,32(s1)
    80006aca:	0027d783          	lhu	a5,2(a5)
    80006ace:	04f70863          	beq	a4,a5,80006b1e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006ad2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ad6:	6898                	ld	a4,16(s1)
    80006ad8:	0204d783          	lhu	a5,32(s1)
    80006adc:	8b9d                	andi	a5,a5,7
    80006ade:	078e                	slli	a5,a5,0x3
    80006ae0:	97ba                	add	a5,a5,a4
    80006ae2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ae4:	00278713          	addi	a4,a5,2
    80006ae8:	0712                	slli	a4,a4,0x4
    80006aea:	9726                	add	a4,a4,s1
    80006aec:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006af0:	e721                	bnez	a4,80006b38 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006af2:	0789                	addi	a5,a5,2
    80006af4:	0792                	slli	a5,a5,0x4
    80006af6:	97a6                	add	a5,a5,s1
    80006af8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006afa:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006afe:	ffffc097          	auipc	ra,0xffffc
    80006b02:	8b6080e7          	jalr	-1866(ra) # 800023b4 <wakeup>

    disk.used_idx += 1;
    80006b06:	0204d783          	lhu	a5,32(s1)
    80006b0a:	2785                	addiw	a5,a5,1
    80006b0c:	17c2                	slli	a5,a5,0x30
    80006b0e:	93c1                	srli	a5,a5,0x30
    80006b10:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b14:	6898                	ld	a4,16(s1)
    80006b16:	00275703          	lhu	a4,2(a4)
    80006b1a:	faf71ce3          	bne	a4,a5,80006ad2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006b1e:	0023d517          	auipc	a0,0x23d
    80006b22:	aa250513          	addi	a0,a0,-1374 # 802435c0 <disk+0x128>
    80006b26:	ffffa097          	auipc	ra,0xffffa
    80006b2a:	308080e7          	jalr	776(ra) # 80000e2e <release>
}
    80006b2e:	60e2                	ld	ra,24(sp)
    80006b30:	6442                	ld	s0,16(sp)
    80006b32:	64a2                	ld	s1,8(sp)
    80006b34:	6105                	addi	sp,sp,32
    80006b36:	8082                	ret
      panic("virtio_disk_intr status");
    80006b38:	00002517          	auipc	a0,0x2
    80006b3c:	d4850513          	addi	a0,a0,-696 # 80008880 <syscalls+0x410>
    80006b40:	ffffa097          	auipc	ra,0xffffa
    80006b44:	a00080e7          	jalr	-1536(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
