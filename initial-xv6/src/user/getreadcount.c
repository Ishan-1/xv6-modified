#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/riscv.h"
#include "user/user.h"
int main()
{
    printf("Count: %d\n",getreadcount());
    return 0;
}