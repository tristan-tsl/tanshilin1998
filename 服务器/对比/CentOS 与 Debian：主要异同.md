2021 年 2 月 11 日

# CentOS 与 Debian：主要异同

操作系统

开源

通过 [丰富的Alloway](https://www.openlogic.com/blog/centos-vs-debian#authorrichalloway)

选择合适的 Linux 发行版对于任何组织来说都是一个重大决定。对于考虑 CentOS 与 Debian 的组织，了解两者之间的主要区别是关键。

在这篇博客中，我们将 CentOS 与 Debian 进行比较，包括架构、包管理、升级、支持等方面的比较。

- [CentOS 与 Debian：概述](https://www.openlogic.com/blog/centos-vs-debian#overview)
- [CentOS 与 Debian：架构](https://www.openlogic.com/blog/centos-vs-debian#architecture)
- [CentOS 与 Debian：包管理](https://www.openlogic.com/blog/centos-vs-debian#package-management)
- [CentOS 与 Debian：文件系统](https://www.openlogic.com/blog/centos-vs-debian#filesystems)
- [CentOS 与 Debian：内核](https://www.openlogic.com/blog/centos-vs-debian#kernel)
- [CentOS 与 Debian：升级](https://www.openlogic.com/blog/centos-vs-debian#upgrading)
- [CentOS 与 Debian：支持](https://www.openlogic.com/blog/centos-vs-debian#support)
- [最后的想法](https://www.openlogic.com/blog/centos-vs-debian#final-thoughts)

## CentOS 与 Debian：概述

CentOS 和 Debian 是从蜡烛的两端产生的 Linux 发行版。

> CentOS 是商业 Red Hat Enterprise Linux 发行版的免费下游重建，相比之下，Debian 是免费的上游发行版，是其他发行版（包括 Ubuntu Linux 发行版）的基础。

与许多 Linux 发行版一样，CentOS 和 Debian 通常相似多于不同；直到我们深入挖掘，我们才能找到它们的分支。

> ### 获取企业 Linux 决策者指南
>
> 如果您正在尝试为您的公司决定最佳的企业 Linux 发行版，那么本指南是必读的。包含 20 个顶级免费和付费企业 Linux 发行版的战斗卡，以及来自我们 Linux 专家的分析，它是每个决策制定者都应掌握的指南。
>
> [免费下载](https://www.openlogic.com/resources/decision-makers-guide-enterprise-linux)

### CentOS 与 Debian：架构

可用的支持架构可能是决定发行版是否可行的决定因素。Debian 和 CentOS 在 x86_64/AMD64 上都非常流行，但它们各自支持哪些其他架构？

Debian 和 CentOS 都支持 AArch64/ARM64、armhf/armhfp、i386、ppc64el/ppc64le。（注：armhf/armhfp 和 i386 仅在 CentOS 7 中受支持。）

CentOS 7 还支持 POWER9，而 Debian 和 CentOS 8 不支持。CentOS 7 专注于 x86_64/AMD64 架构，其他架构通过 AltArch SIG（替代架构特别兴趣小组）发布，CentOS 8 同等支持 x86_64/AMD64、AArch64 和 ppc64le。

Debian 支持 MIPSel、MIPS64el 和 s390x，而 CentOS 不支持。与 CentOS 8 非常相似，Debian 不偏爱一种架构——所有支持的架构都得到同等支持。

### CentOS 与 Debian：包管理

现在大多数 Linux 发行版都有某种形式的包管理器，其中一些比其他的更复杂，功能更丰富。

CentOS 使用 RPM 包格式和 YUM/DNF 作为包管理器。

Debian 使用 DEB 包格式和 dpkg/APT 作为包管理器。

两者都提供具有基于网络的存储库支持、依赖项检查和解析等的全功能包管理。如果您熟悉其中一个但不熟悉另一个，您可能会在切换时遇到一些麻烦，但它们并没有太大的不同. 它们都具有相似的功能，只是可以通过不同的界面使用。

### CentOS 与 Debian：文件系统

您是否考虑使用默认文件系统？如果是这样，XFS 粉丝可以为它是 CentOS 的默认设置而高兴。那些更倾向于 EXT4 的人可能更喜欢 Debian。XFS 和 EXT4 都是 CentOS 和 Debian 的流行和支持良好的选项，因此默认文件系统可能不是决定因素。此外，两个发行版都支持许多其他文件系统，例如 ext2/3、NFSv3/4、btrfs、SMB、GFS2 等等。（注：btrfs 仅受 CentOS 7 支持。）

CentOS 并未正式支持 Debian 提供的某些文件系统。最值得注意的是 ZFS。Debian 通过 DKMS 贡献提供 ZFS 支持，但 CentOS 根本不支持 ZFS（尽管 ZFS 支持[可通过 3rd 方获得](https://openzfs.github.io/openzfs-docs/Getting Started/RHEL and CentOS.html)）。

### CentOS 与 Debian：内核

需要在您的环境中使用最新/最好的 Linux 内核来支持最新的硬件或内核功能吗？在这种情况下，您可能会发现 Debian 的 4.19 内核很有吸引力。

CentOS 确实有[kernel-lt-5.4](http://elrepo.org/tiki/kernel-lt)和[kernel-ml-5.10](http://elrepo.org/tiki/kernel-ml)软件包可通过 3rd 方存储库获得，但 CentOS 附带内核 3.10 (CentOS 7) 或 4.18 (CentOS 8)。

不过，Debian 和 Red Hat 都将安全修复程序从较新的内核反向移植到它们当前的内核中，因此在安全性方面落后通常不是问题。

### CentOS 与 Debian：升级

给 Debian 带来优势的一项功能是主要版本升级。CentOS 支持小版本升级，例如 CentOS 7.8 到 CentOS 7.9，但不支持（或仅弱支持）大版本升级，例如从 CentOS 6 到 CentOS 7 或 CentOS 8。CentOS 主要版本通常有 10 年的生命周期，但就地升级会使系统处于不确定状态，介于一个主要版本和另一个主要版本之间，因此我们通常不推荐它们。（注意：我们建议在 CentOS 主要版本之间进行离线/并行构建升级。）

Debian 从一个稳定版本升级到另一个稳定版本的能力，例如从 Debian 9 Stretch（稳定版）升级到 Debian 10 Buster（稳定版），可以帮助系统在多年后保持最新状态。Debian 通常以 2 年的发布周期发布一个新的主要版本，提供 3 年的全面支持和额外的 2 年 LTS（长期支持），为期 5 年，因此能够升级到下一个稳定的主要版本很方便。

主要版本升级对于那些以更短暂的方式部署系统的人来说没有多大用处，因为将基本映像更新到更新版本通常相对容易，但对于那些部署预计具有多年期的系统的人来说生命周期，主要版本升级可能会带来很大的工作量。

### CentOS 与 Debian：支持

CentOS 在很大程度上得到社区的支持，但 Red Hat 确实接受最终用户为 CentOS 和上游 RHEL 版本提交的错误报告。CentOS 商业支持不直接从 CentOS 项目（或 Red Hat）提供，而是通过 3rd 方提供，例如[OpenLogic](https://www.openlogic.com/enterprise-support-centos)。

Debian 主要受社区支持，包括提供错误跟踪器。Debian 确实提供了一份可以聘请来帮助解决问题的顾问名单，但这些顾问是独立运作的。

一些基于 Debian 的下游发行版具有商业支持选项，其中[Ubuntu](https://www.openlogic.com/blog/centos-vs-ubuntu)可能是最多产的。

## 最后的想法

最后，选择最适合您的发行版归结为技术要求、内部资源、支持选项和业务决策。

如果您出于应用程序的原因必须在兼容 RHEL 的发行版上运行，那么 CentOS 是赢家。如果您的工程团队的经验是使用 DEB 包的发行版，那么 Debian 将是一个明智的选择。

如果您可以完全通过内部人才库来支持您的系统，那么 CentOS 和 Debian 都可以成为选择。但是，如果你想支持你的选择并获得商业支持，也许商业[CentOS 支持选项](https://www.openlogic.com/enterprise-support-centos)会影响你。