################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
LD_SRCS += \
../src/lscript.ld 

C_SRCS += \
../src/main.c \
../src/montgomery.c \
../src/mp_arith.c \
../src/warmup.c 

S_UPPER_SRCS += \
../src/asm_func.S 

OBJS += \
./src/asm_func.o \
./src/main.o \
./src/montgomery.o \
./src/mp_arith.o \
./src/warmup.o 

S_UPPER_DEPS += \
./src/asm_func.d 

C_DEPS += \
./src/main.d \
./src/montgomery.d \
./src/mp_arith.d \
./src/warmup.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.S
	@echo 'Building file: $<'
	@echo 'Invoking: ARM v7 gcc compiler'
	arm-none-eabi-gcc -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -I/home/gustdewit/KULeuven/Digital_Design_Platforms/ddp_g01/sw_package_2025/sw_project/project_sw/ecc_project_wrapper/export/ecc_project_wrapper/sw/ecc_project_wrapper/standalone_domain/bspinclude/include -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM v7 gcc compiler'
	arm-none-eabi-gcc -Wall -O0 -g3 -c -fmessage-length=0 -MT"$@" -mcpu=cortex-a9 -mfpu=vfpv3 -mfloat-abi=hard -I/home/gustdewit/KULeuven/Digital_Design_Platforms/ddp_g01/sw_package_2025/sw_project/project_sw/ecc_project_wrapper/export/ecc_project_wrapper/sw/ecc_project_wrapper/standalone_domain/bspinclude/include -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


