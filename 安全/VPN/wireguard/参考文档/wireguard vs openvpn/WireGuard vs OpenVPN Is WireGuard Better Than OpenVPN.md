# WireGuard 与 OpenVPN

![JP Jones - CTO @ Top10VPN](https://www.top10vpn.com/_next/image/?url=https%3A%2F%2Fwww.top10vpn.com%2Fimages%2F2019%2F08%2FJP-Jones-Bio-Pic-80x80.jpg&w=64&q=75)

[JP琼斯](https://www.top10vpn.com/about/vpn-experts/jpjones/)

2021 年 8 月 6 日更新

------

JP 是我们的 CTO。他拥有超过 25 年的软件工程和网络经验，负责监督我们 VPN 测试过程的所有技术方面。[阅读完整的生物](https://www.top10vpn.com/about/vpn-experts/jpjones/)



1. ![img](data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgdmVyc2lvbj0iMS4xIi8+)

   ![Top10VPN 标志](https://www.top10vpn.com/_next/image/?url=%2Fstatic%2Fimages%2Flogo-simplified-dark.svg&w=32&q=75)

2. [指南](https://www.top10vpn.com/guides/)

3. [WireGuard 与 OpenVPN](https://www.top10vpn.com/guides/wireguard-vs-openvpn/)

## 我们的判决

WireGuard 比 OpenVPN 快得多。它还消耗大约 15% 的数据，更好地处理网络变化，并且看起来同样安全。但是，OpenVPN 已经过彻底的尝试和测试，对隐私更加友好，并且得到更多 VPN 的支持。WireGuard 是一个优秀的 VPN 协议，但 OpenVPN 仍然是最注重隐私的用户的最佳选择。

![Surfshark VPN 协议选择设置中的 WireGuard 和 OpenVPN 选项](https://www.top10vpn.com/images/2021/05/wireguard-openvpn-protocol-choice-surfshark.png)

Surfshark 支持 WireGuard 和 OpenVPN 协议。

虚拟专用网络 (VPN) 使用[VPN 协议](https://www.top10vpn.com/what-is-a-vpn/vpn-protocols/)来创建和保护您的连接。两个最好和最常用的协议是**OpenVPN**和**WireGuard**。

OpenVPN 自 2001 年以来一直存在，传统上被视为行业的黄金标准。但是，新的 WireGuard VPN 协议自 2019 年发布以来就突然出现，现在威胁要从 OpenVPN 手中夺走这一桂冠。

在本深入指南中，我们比较了 OpenVPN 和 WireGuard，以了解您应该使用哪种 VPN 协议。

我们广泛的实验室测试揭示了哪种协议在七个关键领域是最好的，包括**安全性**、**速度**、**隐私**、**易用性**等等。

我们还将告诉您这些协议是如何形成的，提供一些有关谁支持它们的背景信息，并解释它们工作方式的差异。

首先，这里简要总结了 OpenVPN 和 WireGuard 在每个关键类别中的比较：

| **类别**             | **优胜者**                                                   |
| :------------------- | :----------------------------------------------------------- |
| **速度**             | **线卫**如果正确实施，WireGuard 的速度是 OpenVPN 的两倍。    |
| **安全与加密**       | **领带**这两个协议都没有任何已知的安全漏洞。                 |
| **绕过审查**         | **开放式VPN**OpenVPN 更擅长绕过审查者（例如中国防火墙），因为它可以使用 TCP 端口 443。 |
| **流动性**           | **线卫**WireGuard 为移动用户提供比 OpenVPN 更可靠的连接，因为它可以更好地处理网络变化。 |
| **数据使用**         | **线卫**OpenVPN 增加了高达 20% 的数据开销，而 WireGuard 仅使用了 4% 的数据（与不使用 VPN 相比）。 |
| **隐私和日志**       | **开放式VPN**VPN 服务需要包括缓解措施以确保使用 WireGuard 时的用户隐私。 |
| **VPN 和设备兼容性** | **开放式VPN**与 WireGuard 相比，OpenVPN 目前在更多设备上得到更多 VPN 的支持。 |

继续阅读这两种协议的介绍，或使用下面的类别链接跳到对您最重要的部分。

本指南的内容

1. [速度比较](https://www.top10vpn.com/guides/wireguard-vs-openvpn/#wireguard-vs-openvpn-speed-comparison)
2. [加密与安全](https://www.top10vpn.com/guides/wireguard-vs-openvpn/#wireguard-vs-openvpn-encryption--security)
3. [绕过审查](https://www.top10vpn.com/guides/wireguard-vs-openvpn/#wireguard-vs-openvpn-bypassing-censorship)
4. [流动性](https://www.top10vpn.com/guides/wireguard-vs-openvpn/#wireguard-vs-openvpn-mobility)
5. [数据使用](https://www.top10vpn.com/guides/wireguard-vs-openvpn/#wireguard-vs-openvpn-data-usage)
6. [隐私和日志](https://www.top10vpn.com/guides/wireguard-vs-openvpn/#wireguard-vs-openvpn-privacy--logging)
7. [VPN 和设备兼容性](https://www.top10vpn.com/guides/wireguard-vs-openvpn/#wireguard-vs-openvpn-vpn--device-compatibility)

## 什么是 OpenVPN 和 WireGuard？

OpenVPN 和 WireGuard 是两种类型的 VPN 协议。VPN 协议是一种用于在您的设备和 VPN 服务器之间创建安全隧道的技术。（[在此处](https://www.top10vpn.com/what-is-a-vpn/how-does-a-vpn-work/)了解有关[VPN 工作原理的](https://www.top10vpn.com/what-is-a-vpn/how-does-a-vpn-work/)更多信息）。

您可以独立使用 OpenVPN 和 WireGuard 来创建自己的 VPN 连接。但是，它们更常用作[商业 VPN 服务的一部分](https://www.top10vpn.com/best-vpn/)。

以下是每个协议主要功能的概述：

| **特征**     | **开放式VPN**     | **线卫**           |
| :----------- | :---------------- | :----------------- |
| **发布日期** | 2001 年 5 月      | 2019 年 9 月       |
| **加密**     | AES、河豚、山茶花 | ChaCha20、Poly1305 |
| **代码长度** | >70,000 行        | ~4,000 行          |
| **开源**     | 是的              | 是的               |
| **安全**     | 强的              | 强的               |
| **隐私**     | 强的              | 需要缓解措施       |
| **速度**     | 缓和              | 快速地             |

### 开放式VPN![img](https://www.top10vpn.com/images/2019/11/OpenVPN-logo.png)

最初的**OpenVPN**软件是由 James Yonan 于 2001 年创建的。他制作 OpenVPN 是因为他想在穿越中亚并使用亚洲和俄罗斯互联网连接时确保他的连接是私密的。

今天，Yonan 是[OpenVPN Inc](https://openvpn.net/)的 CTO 。该公司提供企业对企业服务以及运行 OpenVPN。该公司的首席执行官兼创始人是 Francis Dinha，他在伊拉克长大，与 Yonan 一样担心隐私不受国家监视。

OpenVPN 软件现在已经从网站上下载了超过**6000 万次**，现在几乎每个 VPN 都支持该协议。它在开源许可下可用，这意味着任何人都可以查看其底层代码。

十多年来，OpenVPN 一直被认为是 VPN 安全的顶峰。然而，随着 WireGuard 的发布，这个头把交椅有了新的竞争者。

### 线卫

![WireGuard 徽标](https://www.top10vpn.com/images/2019/08/WireGuardLogo-min.png)

**WireGuard**由[Edge Security](https://www.edgesecurity.com/)的 Jason A. Donenfeld 创建，并于 2019 年 9 月发布了第一个稳定版本。它旨在通过更简单、更快和更易于使用来改进现有 VPN 协议。

与 OpenVPN 不同，WireGuard 用 Donenfeld 的话来说是“密码学上的自以为是”。这意味着他为 VPN 安全的每个方面都选择了一种解决方案。因此，WireGuard 包含的选择比 OpenVPN 少，但结果却远没有那么复杂。

与 OpenVPN 一样，WireGuard 也是开源的。

尽管 WireGuard 仅在 2019 年 9 月发布，但它已经被整合到许多 VPN 服务中。例如，NordVPN 在其之上构建了其专有的 NordLynx 协议。

那么哪个更好呢？让我们从比较它们的速度开始。

## WireGuard 与 OpenVPN：速度比较

WireGuard 的设计考虑到了速度。OpenVPN 不是。因此，**WireGuard 比 OpenVPN 快得多**。它经过优化，可同时使用多个处理器内核，并使用更快的加密方法。

WireGuard 自己的测量表明，他们的协议至少[比 OpenVPN 快 3 倍](https://www.wireguard.com/performance/)——吞吐量为**1011Mbps**，而 OpenVPN 为**258Mbps**。

![WireGuard 自己的速度测试结果图](https://www.top10vpn.com/images/2021/05/wireguard-speed-test.png)

然而，该团队承认，这些结果“陈旧而粗糙，而且没有很好地进行”，因此我们自己进行了测试，看看哪种协议更快。

### 在大多数 VPN 中，WireGuard 比 OpenVPN 更快

[NordVPN 是一项出色的 VPN 服务](https://www.top10vpn.com/reviews/nordvpn/)，是最早同时支持 WireGuard 和 OpenVPN 的服务之一。因此，它非常适合运行速度测试比较。

我们使用 OpenVPN (UDP) 协议或 NordLynx (WireGuard) 协议连接到世界各地的 NordVPN 服务器并记录我们的连接速度。

以下是我们的 OpenVPN 与 WireGuard 速度结果的摘要：

| 服务器位置 | **OpenVPN (UDP)** | **WireGuard (NordLynx)** |
| :--------- | :---------------- | :----------------------- |
| 英国       | 135Mbps           | 286Mbps（快 112%）       |
| 德国       | 131Mbps           | 277Mbps（快 111%）       |
| 美国       | 142Mbps           | 254Mbps（快 79%）        |
| 日本       | 139Mbps           | 269Mbps（快 94%）        |
| 澳大利亚   | 118Mbps           | 207Mbps（快 75%）        |

在 350Mbps 连接上从英国记录的速度测试数据。

无论我们连接到世界上的哪个地方，WireGuard 始终比 OpenVPN**快 75%**以上。

在较短距离的连接上，差异更加明显，WireGuard 的运行速度是 OpenVPN 的两倍多。

这些结果与 NordVPN 在比较 NordLynx 和 OpenVPN 时所看到的相符。他们在一个月内每天进行 8,200 次自动化测试，还发现 NordLynx[比 OpenVPN 快 2 倍](https://nordvpn.com/blog/one-very-strong-reason-to-be-excited-about-nordlynx/)。

**注意：**这些测试使用 OpenVPN UDP 而不是 OpenVPN TCP。这是因为 UDP 通常比 TCP 快，因此我们希望以“最佳”状态记录 OpenVPN。

然后，我们对支持这两种协议的其他 VPN 服务进行了类似的测试。结果如下：

|          | 冲浪鲨VPN | 穆尔瓦德VPN | 私人互联网接入 |         |           |         |
| :------- | :-------- | :---------- | :------------- | :------ | :-------- | :------ |
| 国家     | 开放式VPN | 线卫        | 开放式VPN      | 线卫    | 开放式VPN | 线卫    |
| 英国     | 121Mbps   | 286Mbps     | 345Mbps        | 345Mbps | 228Mbps   | 181Mbps |
| 美国     | 110Mbps   | 261Mbps     | 64Mbps         | 331Mbps | 92Mbps    | 28Mbps  |
| 澳大利亚 | 78Mbps    | 235Mbps     | 261Mbps        | 269Mbps | 111Mbps   | 18Mbps  |

在 350Mbps 连接上从英国记录的速度测试数据。

与 NordVPN 一样，WireGuard 显然是 Surfshark 和 Mullvad VPN 用户的更快协议。

不过，私人互联网访问 (PIA) 的速度测试结果很重要。由于其相对不成熟，一些 VPN 提供商目前提供 WireGuard，但尚未完全优化其服务以最大限度地提高其性能。

Mullvad 是一个很好的案例研究。2021 年 4 月底，它发布了一个更新，更好地将 WireGuard 集成到服务中。

![Mullvad 的性能更新：“连接 WireGuard 的 Windows 用户有望体验到明显的性能提升”](https://www.top10vpn.com/images/2021/05/Mullvad_WireGuard_update.png)

[Mullvad 的新应用发布更新。](https://mullvad.net/en/blog/2021/4/28/newest-app-release-desktop-could-improve-performance-20213/)

在更新之前，WireGuard 上的 VPN 比 OpenVPN 上的**速度慢 70%**左右。更新后，WireGuard 现在是您可以与 Mullvad 一起使用的最快协议。

我们希望看到与其他 VPN（如 PIA）类似的趋势，因为它们致力于将 WireGuard 更好地集成到他们的服务中。

**注意：**我们的速度测试是在 350Mbps 连接上进行的，这可能比您在家庭网络上的速度要高。因此，WireGuard 在这里的优势可能比在日常使用中更为明显，因为它更擅长使用所有可用带宽。

它当然是更快的协议，但 WireGuard 和 OpenVPN 之间的差异在您的设备上可能比上面的数据更微不足道。

### 连接时间

WireGuard 建立连接的速度也比 OpenVPN 快得多。这很重要，因为如果连接丢失或 VPN 隧道由于某种原因中断，您希望 VPN 快速重新连接。

一个[Ars Technica的研究](https://arstechnica.com/gadgets/2018/08/wireguard-vpn-review-fast-connections-amaze-but-windows-support-needs-to-happen/)发现，一个OpenVPN连接可能需要长达8秒钟以启动，而WireGuard连接需要大约100毫秒。

**概括**

**如果正确集成到 VPN 服务中，WireGuard 是比 OpenVPN 快得多的协议。它就是为此目的而设计的，并且做得很好。如果您正在做任何对速度敏感的事情，例如游戏或流媒体，请使用 WireGuard。**

**获胜者：WireGuard**

## WireGuard 与 OpenVPN：加密和安全

|                        | **开放式VPN**                                                | **线卫**           |
| :--------------------- | :----------------------------------------------------------- | :----------------- |
| **加密密码和认证协议** | 常用：AES、河豚、山茶花还支持：ChaCha20、Poly1305 （还有更多） | ChaCha20、Poly1035 |
| **完美的前向保密**     | 支持的                                                       | 支持的             |
| **已知漏洞**           | 没有任何                                                     | 没有任何           |

OpenVPN 允许您使用广泛的加密密码和身份验证算法，而 WireGuard 对每个版本只有一个固定的设置。

这意味着，如果在算法中发现安全漏洞，OpenVPN 可以快速配置为使用其他东西。而 WireGuard 则需要在所有设备上进行软件更新。这很痛苦，但它确保没有设备使用不安全的代码。

> 目前WireGuard 和 OpenVPN 都**没有已知的安全漏洞**。

### 选择与安全

OpenVPN 和 WireGuard 之间的主要区别之一是选择和安全之间的权衡。

OpenVPN 使用 OpenSSL 库进行加密，该库于 1998 年首次发布，并经过了长时间的全面测试。该库支持广泛的加密密码，包括**AES**、**Blowfish**和**ChaCha20**。

另一方面，WireGuard 不提供加密选择。相反，它强制您使用**ChaCha20**进行加密，使用**Poly1305**进行身份验证。

因此，WireGuard 需要的代码比 OpenVPN 少得多——大约 4,000 行，而 70,000 行（至少）。这种较小的占用空间使安全研究人员比 OpenVPN 更容易审计和验证 WireGuard 的代码。它还使 WireGuard 的可能攻击面比 OpenVPN 小得多。

**概括**

**OpenVPN 在加密和安全性方面提供了更大的自由度，但 WireGuard 更容易审核并且攻击面更小。这两种协议都非常安全，但不太懂技术的用户可能更愿意信任 WireGuard 的专家，而不是自己解决问题。**

### 新的加密算法安全吗？

通常，安全研究人员更喜欢已经存在一段时间的加密技术。这是因为较新的算法有时可能具有尚未识别的漏洞。因此，采用更久经考验的选项通常更安全。

在这种情况下，OpenVPN 是迄今为止最久经考验的选项。它比 WireGuard 早 18 年发布，它使用的 AES 密码比 WireGuard 使用的 ChaCha20 和 Poly1035 算法早了近十年。

然而，在实践中，WireGuard 的相对不成熟似乎并不是一个巨大的安全风险。造成这种情况的主要原因有以下三个：

1. **WireGuard 的最小代码库意味着可以非常快速地对其进行审核。**这减轻了对该协议缺乏严格测试的许多担忧，因为专家可以比 OpenVPN 的代码更快地对其进行审核。
2. **ChaCha20 非常安全。**“ChaCha20”中的“20”表示有20轮加密来保护数据。2008年，ChaCha7（七轮）被打破，但ChaCha8至今[未破](https://security.googleblog.com/2019/02/introducing-adiantum-encryption-for.html)。因此您可以确信 ChaCha20 提供了高度的安全性。
3. **来自 Linux 和 Google 的认可。** [Linux 的原始创造者 Linus Torvalds 说](http://lkml.iu.edu/hypermail/linux/kernel/1808.0/02472.html)：“我能否再次表达我对 [WireGuard] 的热爱……也许代码并不完美，但我已经略读过了，与 OpenVPN 和 IPSec 的恐怖相比，这是一件艺术品。” WireGuard 已被包含在 Linux 内核中，这代表了对其安全凭证的强大支持。谷歌还转而使用 ChaCha20 和 Poly1305 来[加密其 Android 设备上的流量](https://www.infosecurity-magazine.com/news/google-swaps-out-crypto-ciphers-in-openssl/)。

**概括**

**WireGuard 和 OpenVPN 都是非常安全的 VPN 协议。哪种加密和安全性更好主要取决于个人喜好。**



**如果您对更新的技术持谨慎态度或希望对您的安全设置有更多的控制，那么 OpenVPN 是您更好的选择。如果您喜欢高效、简化的代码库的想法，那么请选择 WireGuard。**

**赢家：没有明确的赢家。这是一个平局。**

## WireGuard 与 OpenVPN：绕过审查

OpenVPN 和 WireGuard 都是非常可靠的 VPN 协议，可在大多数情况下提供稳定的互联网连接。

但是，只有 OpenVPN 为您提供使用 TCP 通信协议的选项。这有助于绕过严格的审查制度，因为 TCP 连接能够使用**端口 443**，这与常规 HTTPS 流量使用的端口相同。

中国、俄罗斯和土耳其等国家的审查系统极不可能封锁 443 端口，因为它会阻止在线银行和购物等基本活动。

> 简而言之，OpenVPN TCP 在绕过审查方面比 WireGuard 更有效，因为 WireGuard 只能与 UDP 一起使用。

以下是 UDP 和 TCP 比较的快速总结：

|                    | **用户数据报协议 (UDP)** | **传输控制协议 (TCP)** |
| :----------------- | :----------------------- | :--------------------- |
| **WireGuard 支持** | ✓                        | ✗                      |
| **OpenVPN 支持**   | ✓                        | ✓                      |
| **可靠性特点**     | ✗                        | ✓                      |
| **速度**           | 快点                     | 慢点                   |

我们通常建议尽可能使用 UDP，因为它在 VPN 隧道中使用时速度更快、效率更高且同样稳定。然而，为了绕过防火墙和规避审查，TCP 协议更可取。

这反映在您尝试在中国连接时 VPN 服务的默认选项。

我们发现，几乎在所有情况下，当 VPN 提供商同时提供 WireGuard 和 OpenVPN 时，当您尝试从中国境内连接时，该服务将默认使用 OpenVPN 协议。

我们还测试了一些我们知道在中国运行良好的 VPN 服务，以查看 OpenVPN 或 WireGuard 是否更擅长绕过中国的防火墙：

- Astrill VPN能够击败使用审查**双方**的OpenVPN和WireGuard
- Private Internet Access (PIA) 只能在使用**OpenVPN**时连接，使用 WireGuard 失败。

**概括**

**OpenVPN 是绕过审查的更好选择。它使您能够使用审查系统很难阻止的端口 443。如果您尝试从中国和阿联酋等国家/地区访问免费的全球互联网，请使用 OpenVPN (TCP)。**

**获胜者：OpenVPN**

## WireGuard 与 OpenVPN：移动性

![ExpressVPN 在移动设备上的新应用](https://www.top10vpn.com/images/2021/01/ExpressVPN-new-mobile-app-2021.png)

今天的设备经常在移动网络和 WiFi 网络之间移动。一个好的 VPN 协议需要能够有效地进行切换。

**WireGuard 在移动性方面远优于 OpenVPN。**它无缝地处理网络变化，而 OpenVPN 历来在用户定期在网络之间切换时遇到困难。许多 VPN 服务实际上选择对移动设备使用不同的协议 IKEv2。

[IKEv2](https://www.top10vpn.com/what-is-a-vpn/vpn-protocols/)是一个相当不错的 VPN 协议，但它是闭源的，有些人担心它可能已被 NSA 破坏。相反，WireGuard 提出了一种新的开源解决方案，用于解决在移动设备上使用哪种 VPN 协议的问题。

如果您在旅途中使用 VPN，我们强烈建议您使用 WireGuard 而不是 OpenVPN。

**概括**

**与 OpenVPN 不同，WireGuard 能够出色地应对常规网络变化。它还比 IKEv2 更快、更隐私，IKEv2 是许多 VPN 服务当前针对移动用户的默认协议。**

**获胜者：WireGuard**

## WireGuard 与 OpenVPN：数据使用

使用 VPN 总是会增加您消耗的数据总量。这是因为隧道过程需要您通过互联网发送额外信息，这会导致数据使用量增加。

数据开销会影响 VPN 的速度。如果您签订的是即用即付的手机合同，您可能还会花更多的钱和/或更快地达到计划的数据限制。

您使用的 VPN 协议会影响数据开销的大小。我们的研究发现 WireGuard 消耗的数据远少于 OpenVPN。以下是调查结果的摘要：

![条形图显示 OpenVPN TCP (+19.96%)、OpenVPN UDP (+17.23%) 和 WireGuard (+4.53%) 的数据消耗](https://www.top10vpn.com/images/2021/05/wireguard-vs-openvpn-data-comparison.png)

为了测试每个协议的数据使用情况，我们使用了 Linux WireGuard 和 OpenVPN 应用程序，并计算了与不使用 VPN 相比，它们向我们的连接添加了多少额外数据。对于每个测试，我们在两个虚拟服务器之间复制了一个 209MB 的测试文件。我们每个测试进行了 3 次，并计算出平均数据增加量。

**结果：** WireGuard 使用的数据比 OpenVPN 少得多。虽然 OpenVPN UDP 具有 17.23% 的大数据开销，但 WireGuard 仅增加了 4.53% 的数据消耗。使用 OpenVPN TCP 时，此开销更大，为 19.96%。

在我们测试过的任何 VPN 协议（包括 IKEv2 和 PPTP）中，WireGuard 实际上具有**最小的数据开销**。相比之下，OpenVPN 最大。

您可以在我们的[移动数据和 VPN](https://www.top10vpn.com/what-is-a-vpn/does-vpn-use-data/)指南中查看此调查的完整结果，并了解有关 VPN 数据使用情况的更多信息。

**概括**

**WireGuard 消耗的数据比 OpenVPN 少得多。如果您的互联网访问有数据上限，或者根据您消耗的带宽量收费，请使用 WireGuard。**

**获胜者：WireGuard**

## WireGuard 与 OpenVPN：隐私和日志记录

| 协议          | **日志记录**                          | **缓解措施**                |
| :------------ | :------------------------------------ | :-------------------------- |
| **开放式VPN** | 没有任何                              | 不需要                      |
| **线卫**      | IP 地址存储在服务器上，直到它重新启动 | 可用于大多数商业 VPN 提供商 |

安全 VPN 服务的一个基本特征是它不存储有关您的任何个人身份信息。这也适用于正在使用的 VPN 协议。

虽然 OpenVPN 无需记录 IP 地址即可工作，但**WireGuard 需要将允许的 IP 地址存储在服务器上，直到服务器重新启动。**

从隐私的角度来看，这是令人担忧的，因为如果服务器遭到破坏，IP 地址可用于将您链接到您的活动，从而消除使用 VPN 的主要好处。

请注意，如果您使用的是 WireGuard 的标准实现，则您的 IP 地址可能至少在会话期间被记录。

值得庆幸的是，大多数支持 WireGuard 的商业 VPN 服务都实施了变通方法以最大程度地减少这些隐私风险。一些例子包括：

- **[NordVPN：](https://nordvpn.com/blog/nordlynx-protocol-wireguard/)** NordVPN 将 WireGuard 与其专有的双网络地址转换 (NAT) 技术相结合，以创建 NordLynx。NordLynx 不会在服务器重新启动之前存储您的静态 IP 地址，而是为每个 VPN 隧道分配一个唯一的动态 IP 地址，这样每个会话都有一个不同的 IP 地址，该地址的持续时间与会话一样长。
- **[Mullvad：](https://mullvad.net/en/help/why-wireguard/)**为了在使用 WireGuard 时最大限度地保护隐私，Mullvad 会在 10 分钟不活动后从其服务器中删除您的 IP 地址。作为一个额外的步骤，Mullvad 还建议您在使用 WireGuard 时使用其多跳功能通过两个或更多服务器路由您的流量。
- **[IVPN：](https://www.ivpn.net/wireguard/)** IVPN 会在三分钟不活动后删除您的 IP 地址。它还每 24 小时随机生成一个新的 IP 地址，以避免出现使用静态 IP 地址的问题。

这些缓解措施对大多数用户来说已经足够了。但是，如果您在一个严格审查的国家或一个[官员可能试图起诉 VPN 用户的国家](https://www.top10vpn.com/what-is-a-vpn/are-vpns-legal/)，那么这可能不值得冒险。

如果您担心自己的隐私，我们还建议您咨询您的 VPN 提供商，他们为 WireGuard 用户提供了哪些缓解措施。

**概括**

**与 OpenVPN 不同，WireGuard 协议要求您的 IP 地址在 VPN 服务器上存储较长时间。VPN 服务可以而且将会减轻这种情况，但从隐私的角度来看，这并不理想。OpenVPN 不需要此类缓解措施。**

**获胜者：OpenVPN**

## WireGuard 与 OpenVPN：VPN 和设备兼容性

几乎所有商业 VPN 服务都原生支持 OpenVPN，而 WireGuard 的可用范围要小得多。不过，它正在快速追赶。尽管仅在 2019 年发布，但 WireGuard 已经在许多领先的 VPN 中实施——通常跨桌面和移动应用程序。

以下是 15 种最流行的 VPN 支持哪些协议的概述：

| VPN协议       | **ExpressVPN** | **NordVPN** | **网络幽灵** | **IPVanish** | **冲浪鲨** | **私人VPN** | **PIA** | **Windscribe** | **质子VPN** | **阿斯特里尔** | **隐藏我的屁股** | **热点盾** | **穆尔瓦德** | **隧道熊** | **纯VPN** |
| :------------ | :------------- | :---------- | :----------- | :----------- | :--------- | :---------- | :------ | :------------- | :---------- | :------------- | :--------------- | :--------- | :----------- | :--------- | :-------- |
| **开放式VPN** | ✓              | ✓           | ✓            | ✓            | ✓          | ✓           | ✓       | ✓              | ✓           | ✓              | ✓                | ✗          | ✓            | ✓          | ✓         |
| **线卫**      | ✗              | ✓           | ✓            | ✗            | ✓          | ✗           | ✓       | ✓              | ✗           | ✓              | ✗                | ✗          | ✓            | ✗          | ✗         |

传统上，大多数 VPN 使用 OpenVPN 作为其默认协议，尤其是在桌面上。但是，我们现在看到越来越多的提供商转向 WireGuard。例如，CyberGhost 现在默认在 Android 和 iOS 上使用 WireGuard，而 NordVPN 在其大多数应用程序中默认使用其 NordLynx 版本的 WireGuard。

**注意：**要在路由器上使用 VPN，您可能仍需要使用 OpenVPN。上面列表中只有 Mullvad 在路由器级别与 WireGuard 配合使用。

### 便于使用

要自己手动配置协议，WireGuard 比 OpenVPN 容易得多。同样，这是由于 WireGuard 的简化代码以及在加密配置方面缺乏选择，这使得安装非常简单。

WireGuard 的轻量级代码库也是在小型计算设备和嵌入式设备上使用 VPN 的优势。例如，OVPN 包括[适用](https://www.ovpn.com/en/guides/wireguard/raspberry-pi-raspbian)于 Raspberry Pi 单板计算机的[WireGuard 兼容命令行应用程序](https://www.ovpn.com/en/guides/wireguard/raspberry-pi-raspbian)。

也就是说，OpenVPN 对大多数 VPN 用户来说更容易使用，仅仅是因为它得到了更多 VPN 服务的原生支持。只需下载您选择的 VPN，几乎在所有情况下，OpenVPN 协议都将被设置并可供使用。

**概括**

**OpenVPN 已经存在了将近二十年，并且几乎在每个 VPN 应用程序中都得到了原生支持。WireGuard 目前被集成到越来越多的 VPN 中，但您选择的 VPN 提供商仍然更有可能支持 OpenVPN。如果您在路由器上使用 VPN，情况尤其如此。**

**获胜者：OpenVPN**

## 结论

WireGuard 已经给 VPN 行业留下了深刻的印象——许多领先的 VPN 现在都支持它，并且它最近被包含在 Linux 内核中。

OpenVPN 更老、更受信任，当然也更保护隐私，但 WireGuard 速度惊人，而且似乎也非常安全。

因此，对于您的 VPN 连接是否应该使用 OpenVPN 或 WireGuard 的答案取决于您在做什么。

**如果出现以下情况，您应该使用 WireGuard：**

- 你想要最快的速度。
- 您正在使用移动设备并且担心数据消耗。
- 您经常在 WiFi 和蜂窝网络之间切换。
- 您正在手动配置 VPN 或构建自己的 VPN 软件。

**在以下情况下，您应该使用 OpenVPN：**

- 您所在的国家/地区禁止使用 VPN，如果被发现使用 VPN，您可能会面临起诉。
- 您想要最大程度的隐私，并且不喜欢 WireGuard 的额外日志记录要求，即使您的 VPN 提供商有适当的缓解措施。
- 您对新技术更加谨慎，并希望给 WireGuard 更多时间成熟和测试。
- 您正在使用尚不支持 WireGuard 的 VPN 服务。

## 关于作者

------

- ![img](data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgdmVyc2lvbj0iMS4xIi8+)

  ![JP Jones - CTO @ Top10VPN](https://www.top10vpn.com/_next/image/?url=https%3A%2F%2Fwww.top10vpn.com%2Fimages%2F2019%2F08%2FJP-Jones-Bio-Pic.jpg&w=128&q=80)

  JP琼斯

  - [电子邮件](mailto:jp@privacy.co?subject=WireGuard vs OpenVPN)

  JP 是我们的 CTO。他拥有超过 25 年的软件工程和网络经验，负责监督我们 VPN 测试过程的所有技术方面。[阅读完整的生物](https://www.top10vpn.com/about/vpn-experts/jpjones/)