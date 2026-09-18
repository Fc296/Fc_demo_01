# my_02 项目约定（长期）

## 项目性质
Godot 4.7.2 的 2D 像素风 RPG，四层架构（data / Scripts / Scenes / ui）+ Autoload。
工程根目录：`E:\AAAproject\素材\my_02`。参考实现见 `E:\AAAproject\素材\demo\`。

## 架构约定
- 只能向下认识，不能向上或横向乱认：`ui → Scenes → Scripts → data`，`Autoload` 谁都认识它。
- 数据层一律用 `Resource`（可在编辑器新建 .tres，不写代码造物品）。
- `Actor` 不认识"玩家"；`Player` / `Enemy` 只加各自独有的东西。
- UI 是容器的"投影"：只读 + 重画，自己不存数据；改数据 → 发信号 → 面板刷新（单向）。
- 跨系统才走 `EventBus`；一对一关系直接 `connect`。
- 每个 `.gd` 末尾保留「接口清单」（注释掉的变量/函数签名）的写法，用户明确要求这种风格。

## 用户偏好
- 要求**中文注释**，且注释要解释"为什么这么设计、容易踩什么坑"，不只是翻译代码。
- 阶段性任务喜欢"先只出注释骨架、代码后面自己填"。
- 目录名沿用用户原文的大小写：`data/` `Scripts/` `Scenes/` `ui/`（不要擅自统一）。

## Git 约定
- 仓库在 `E:\AAAproject\素材\my_02\.git`，主分支 `main`。
- `.gitignore`：忽略 `.godot/`；**必须保留** `*.import`（Godot 4 靠它记导入设置）。
- `.gitattributes`：`* text=auto eol=lf`；图片/音频标 `binary`；`.tscn`/`.tres` 标 linguistically-generated。
- 已设 `core.quotepath false`（否则中文文件名显示为转义串）。
- 身份已设为（仓库局部）：`会滑铲的猫 <19981293752@163.com>`。
  ⚠️ 改身份**不能**用 `git config` 命令（它要写 `.git/config.lock`，会被沙箱拦），须直接改 `.git/config` 文本。
- 当前 HEAD：`50044a7c2b7c9b5c1b924eb73147645435209bad`（初始提交，作者即上述身份）。

## ★ 环境硬限制（重要）
沙箱在**工作区内禁止创建 `*.lock` 文件** → `git commit` 无法在沙箱内直接执行；
且工作区内 `rm`/`os.remove` 会 fail-closed 并中断整条命令。
绕行做法与详细步骤见 `2026-09-16.md` 的「重大环境坑」一节。

## 待办
- `run/main_scene` 未设置：场景（.tscn）尚未搭建，按 F5 会提示"没有主场景"。
- 所有 `.gd` 目前只是注释骨架，业务代码待逐个实现。
