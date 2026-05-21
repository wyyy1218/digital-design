# 快速测试指南

## 步骤1: 切换到测试程序

编辑 `loongarch_sc/src/Makefile.testcase`，将内容改为：
```
# change the tesctcase name
USER_PROGRAM := test_debug
```

## 步骤2: 编译测试程序

```bash
cd loongarch_sc
make
cd ..
```

## 步骤3: 编译并运行TEMU

```bash
make run
```

## 步骤4: 在TEMU控制台中测试

### 基础测试

1. **测试help命令**
   ```
   (temu) help
   ```

2. **测试info r命令**
   ```
   (temu) info r
   ```

3. **测试si命令**
   ```
   (temu) si 1
   (temu) info r
   ```

4. **测试x命令**
   ```
   (temu) si 10
   (temu) x 5 0x80010000
   ```

5. **测试w命令（设置监视点）**
   ```
   (temu) w $t2
   (temu) info w
   ```

6. **测试监视点触发**
   ```
   (temu) c
   ```
   当$t2值变化时，程序会暂停并显示变化

7. **测试d命令（删除监视点）**
   ```
   (temu) d 0
   (temu) info w
   ```

8. **测试表达式**
   ```
   (temu) x 1 $s0 + 4
   (temu) x 1 ($a0 + $a1)
   ```

9. **退出**
   ```
   (temu) q
   ```

## 完整测试流程（复制粘贴）

```
(temu) help
(temu) info r
(temu) si 5
(temu) info r
(temu) x 5 0x80010000
(temu) w $t2
(temu) w $a0
(temu) info w
(temu) c
(temu) info w
(temu) d 0
(temu) info w
(temu) x 3 $s0
(temu) q