"""Original vector drawings and Vietnamese teaching scripts for ART KID lessons."""

from dataclasses import dataclass, field
import math

INK = "#273444"
CORAL = "#f27059"
YELLOW = "#ffd166"
TEAL = "#35b7a5"
BLUE = "#70b8e8"
PURPLE = "#a58ad4"
GREEN = "#83c985"
BROWN = "#c78e60"
CREAM = "#fff2d7"


@dataclass
class Stroke:
    points: list[tuple[float, float]]
    color: str = INK
    width: int = 4
    fill: str | None = None
    fill_early: bool = False
    text: str | None = None


@dataclass
class Step:
    title: str
    speech: str
    strokes: list[Stroke] = field(default_factory=list)


@dataclass
class Lesson:
    key: str
    course_id: str
    course_title: str
    order: int
    title: str
    goal: str
    practice: str
    steps: list[Step]


def line(*points, color=INK, width=4):
    return Stroke(list(points), color=color, width=width)


def polygon(points, fill=None, early=False, color=INK, width=4):
    return Stroke(list(points) + [points[0]], color, width, fill, early)


def ellipse(cx, cy, rx, ry, fill=None, early=False, color=INK, width=4):
    points = [
        (cx + rx * math.cos(t * 2 * math.pi / 90), cy + ry * math.sin(t * 2 * math.pi / 90))
        for t in range(91)
    ]
    return Stroke(points, color, width, fill, early)


def curve(start, control, end, color=INK, width=4):
    points = []
    for i in range(51):
        t = i / 50
        points.append(
            (
                (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * control[0] + t * t * end[0],
                (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * control[1] + t * t * end[1],
            )
        )
    return Stroke(points, color, width)


def label(text, x, y, color=INK):
    return Stroke([(x, y)], color=color, text=text)


def rays(cx, cy, radius, length, count=8):
    return [
        line(
            (cx + radius * math.cos(a), cy + radius * math.sin(a)),
            (cx + (radius + length) * math.cos(a), cy + (radius + length) * math.sin(a)),
            color=CORAL,
        )
        for a in [i * 2 * math.pi / count for i in range(count)]
    ]


def basic_strokes():
    return [
        Step(
            "Cầm bút thật nhẹ",
            "Bé đặt giấy ngay ngắn và cầm bút thật nhẹ nhé. Chúng mình bắt đầu bằng một nét ngang, kéo bút từ trái sang phải.",
            [line((55, 65), (225, 65), color=CORAL), label("Nét ngang", 80, 20)],
        ),
        Step(
            "Luyện nét ngang",
            "Bé vẽ thêm hai nét ngang bên dưới. Mỗi nét cách nhau một chút. Không cần dùng thước, mình cứ vẽ thật chậm thôi.",
            [line((55, 105), (225, 105), color=CORAL), line((55, 145), (225, 145), color=CORAL)],
        ),
        Step(
            "Nét dọc và nét xiên",
            "Bây giờ kéo bút từ trên xuống dưới để có nét dọc. Sau đó vẽ hai nét nghiêng. Bé thử nghiêng sang trái rồi sang phải nhé.",
            [
                line((310, 55), (310, 150), color=TEAL),
                line((365, 55), (365, 150), color=TEAL),
                line((440, 55), (490, 150), color=BLUE),
                line((540, 55), (490, 150), color=BLUE),
                label("Nét dọc", 285, 20),
                label("Nét xiên", 445, 20),
            ],
        ),
        Step(
            "Uốn bút thành nét cong",
            "Bé đưa bút lên rồi vòng xuống như một chiếc cầu. Ghép hai nét cong, mình sẽ có một làn sóng rất mềm mại.",
            [
                curve((55, 260), (110, 155), (165, 260), color=PURPLE),
                curve((165, 260), (220, 340), (275, 260), color=PURPLE),
                label("Nét cong", 110, 295),
            ],
        ),
        Step(
            "Khép một hình tròn",
            "Bắt đầu ở phía trên, bé đi một vòng chậm rãi và trở về điểm bắt đầu. Hình tròn hơi méo cũng không sao, vì đây là nét vẽ của riêng bé.",
            [ellipse(430, 250, 70, 70, YELLOW), label("Hình tròn", 380, 355)],
        ),
        Step(
            "Tạo một mặt trời",
            "Bé thêm những nét ngắn xung quanh hình tròn để làm tia nắng. Thế là chúng mình đã ghép nét thẳng với nét cong thành một ông mặt trời rồi.",
            rays(430, 250, 83, 17),
        ),
    ]


def colors():
    primary = [
        ellipse(x, 55, 30, 30, color, True)
        for x, color in [(75, CORAL), (175, YELLOW), (275, BLUE)]
    ]
    primary += [label("Đỏ", 60, 95), label("Vàng", 150, 95), label("Xanh", 250, 95)]
    rows = []
    for y, left, right, result, name in [
        (155, CORAL, YELLOW, "#ffab62", "Cam"),
        (235, BLUE, YELLOW, GREEN, "Xanh lá"),
        (315, CORAL, BLUE, PURPLE, "Tím"),
    ]:
        rows.append(
            [
                ellipse(65, y, 24, 24, left, True),
                label("+", 110, y - 13),
                ellipse(165, y, 24, 24, right, True),
                label("=", 210, y - 13),
                ellipse(270, y, 28, 28, result, True),
                label(name, 310, y - 13),
            ]
        )
    flower = [line((480, 230), (480, 325), color=TEAL)]
    for angle in range(0, 360, 60):
        a = math.radians(angle)
        flower.append(ellipse(480 + 37 * math.cos(a), 175 + 37 * math.sin(a), 27, 27, CORAL, True))
    flower.append(ellipse(480, 175, 25, 25, YELLOW, True))
    return [
        Step(
            "Ba màu quen thuộc",
            "Bé cùng nhận biết ba màu: đỏ, vàng và xanh dương. Mình tô từng mảng nhỏ, đưa bút nhẹ tay và cố gắng không vượt ra ngoài đường viền.",
            primary,
        ),
        Step(
            "Đỏ cộng vàng",
            "Với màu nước, bé lấy một chút đỏ trộn cùng một chút vàng. Hai màu này tạo thành màu cam. Mình pha trên khay màu trước khi tô lên giấy nhé.",
            rows[0],
        ),
        Step(
            "Xanh dương cộng vàng",
            "Bé lau sạch cọ, rồi pha xanh dương với màu vàng. Mình sẽ được màu xanh lá, giống như lá cây trong vườn.",
            rows[1],
        ),
        Step(
            "Đỏ cộng xanh dương",
            "Bé dùng cọ sạch pha màu đỏ và xanh dương để thử tạo màu tím. Mỗi loại màu có thể cho sắc tím khác nhau, mình cứ thêm từng chút một nhé.",
            rows[2],
        ),
        Step(
            "Tô thử một bông hoa",
            "Chúng mình dùng màu đỏ tô cánh hoa, màu vàng tô nhụy và màu xanh lá tô cuống. Bé có thể chọn một bộ màu khác nếu thích.",
            flower,
        ),
        Step(
            "Giữ màu sạch và sáng",
            "Bé nhìn lại bảng màu của mình. Sau mỗi màu, nhớ rửa và thấm cọ nhẹ. Nếu dùng bút màu, mình tô một lớp mỏng rồi mới thêm lớp thứ hai.",
            [label("Pha từng chút · Tô nhẹ tay", 390, 45)],
        ),
    ]


def house():
    return [
        Step(
            "Vẽ mái nhà",
            "Bé vẽ một nét xiên đi lên, một nét xiên đi xuống, rồi nối ngang phía dưới. Ba nét này tạo thành mái nhà hình tam giác.",
            [polygon([(145, 125), (300, 25), (455, 125)], CORAL)],
        ),
        Step(
            "Thêm thân nhà",
            "Từ hai góc mái nhà, bé kéo hai nét dọc xuống. Nối hai nét bằng một đường ngang, mình có thân nhà hình chữ nhật.",
            [polygon([(165, 125), (435, 125), (435, 300), (165, 300)], CREAM)],
        ),
        Step(
            "Cửa ra vào",
            "Bé đặt một hình chữ nhật nhỏ ở giữa để làm cửa ra vào. Thêm một chấm nhỏ làm tay nắm. Cánh cửa đã sẵn sàng đón mọi người rồi.",
            [
                polygon([(270, 210), (330, 210), (330, 300), (270, 300)], BROWN),
                ellipse(315, 260, 3, 3, INK),
            ],
        ),
        Step(
            "Hai ô cửa sổ",
            "Hai bên cánh cửa, bé vẽ hai hình vuông nhỏ. Kẻ một nét ngang và một nét dọc trong mỗi ô để chia cửa sổ thành bốn phần.",
            [
                polygon([(195, 160), (245, 160), (245, 210), (195, 210)], BLUE),
                line((220, 160), (220, 210)),
                line((195, 185), (245, 185)),
                polygon([(355, 160), (405, 160), (405, 210), (355, 210)], BLUE),
                line((380, 160), (380, 210)),
                line((355, 185), (405, 185)),
            ],
        ),
        Step(
            "Trang trí quanh nhà",
            "Bé thêm mặt trời ở góc giấy và một lối đi trước cửa. Mình có thể vẽ vài ngọn cỏ nhỏ để ngôi nhà trông thật ấm áp.",
            [
                ellipse(75, 65, 28, 28, YELLOW),
                *rays(75, 65, 38, 12),
                line((270, 300), (245, 345)),
                line((330, 300), (355, 345)),
                line((65, 300), (150, 300), color=TEAL),
                line((450, 300), (550, 300), color=TEAL),
            ],
        ),
        Step(
            "Tô màu ngôi nhà",
            "Bé chọn màu cho mái nhà, tường, cửa và bầu trời. Tô từ mảng lớn đến mảng nhỏ. Ngôi nhà không cần giống mẫu, màu nào làm bé vui cũng được.",
            [],
        ),
    ]


def flower():
    petals = []
    for angle in range(0, 360, 60):
        a = math.radians(angle)
        petals.append(ellipse(300 + 65 * math.cos(a), 120 + 65 * math.sin(a), 42, 42, CORAL))
    return [
        Step(
            "Tìm vị trí bông hoa",
            "Bé đặt bông hoa ở khoảng giữa phía trên tờ giấy. Vẽ một vòng tròn nhỏ để làm nhụy hoa, chừa đủ chỗ xung quanh cho các cánh.",
            [ellipse(300, 120, 30, 30, YELLOW)],
        ),
        Step(
            "Ba cánh đầu tiên",
            "Bé vẽ ba nét vòng tròn mềm ở quanh nhụy. Mỗi cánh là một hình tròn hoặc hình bầu dục. Cánh to nhỏ khác nhau vẫn rất xinh.",
            petals[:3],
        ),
        Step(
            "Hoàn thành cánh hoa",
            "Mình vẽ thêm ba cánh ở phần còn trống. Đường cánh chạm vào nhau sẽ làm bông hoa trông tròn trịa và đầy đặn hơn.",
            petals[3:] + [ellipse(300, 120, 30, 30, YELLOW)],
        ),
        Step(
            "Cuống và lá",
            "Từ dưới bông hoa, bé kéo một đường cong xuống để làm cuống. Hai bên cuống, vẽ hai chiếc lá nhọn đầu, rồi thêm đường gân ở giữa lá.",
            [
                curve((300, 220), (285, 265), (300, 325), color=TEAL),
                polygon([(294, 280), (230, 235), (235, 280)], GREEN),
                line((294, 280), (245, 252), color=TEAL),
                polygon([(295, 300), (370, 245), (360, 295)], GREEN),
                line((295, 300), (350, 267), color=TEAL),
            ],
        ),
        Step(
            "Trang trí khu vườn",
            "Bé thêm vài ngọn cỏ ở chân cuống. Nếu còn chỗ, mình có thể vẽ thêm một bông hoa nhỏ ở bên cạnh để khu vườn có bạn.",
            [
                line((155, 330), (155, 305), color=TEAL),
                line((155, 330), (140, 315), color=TEAL),
                line((445, 330), (445, 305), color=TEAL),
                line((445, 330), (460, 310), color=TEAL),
            ],
        ),
        Step(
            "Tô cánh và nhụy",
            "Bé tô nhụy màu vàng và chọn màu mình thích cho các cánh hoa. Phần cuống và lá có thể dùng hai sắc xanh khác nhau. Vậy là bông hoa đã nở rồi.",
            [],
        ),
    ]


def landscape():
    return [
        Step(
            "Chia bầu trời và mặt đất",
            "Bé kẻ một đường ngang nhẹ ở khoảng giữa tờ giấy. Phần trên là bầu trời, phần dưới dành cho mặt đất và dòng sông.",
            [line((35, 205), (565, 205), color=TEAL)],
        ),
        Step(
            "Hai ngọn núi",
            "Bé vẽ hai hình tam giác lớn nhỏ ở phía xa. Ngọn núi phía sau có thể cao hơn. Mình không cần vẽ hai ngọn giống hệt nhau.",
            [
                polygon([(155, 205), (295, 55), (430, 205)], PURPLE),
                polygon([(310, 205), (430, 105), (550, 205)], BLUE),
            ],
        ),
        Step(
            "Mặt trời và mây",
            "Ở một góc trời, bé vẽ mặt trời bằng hình tròn và những tia nắng ngắn. Mình ghép vài nét cong lại thành một đám mây mềm.",
            [
                ellipse(505, 45, 25, 25, YELLOW),
                *rays(505, 45, 35, 9),
                curve((70, 75), (75, 25), (110, 55)),
                curve((110, 55), (145, 5), (170, 65)),
                curve((170, 65), (220, 45), (220, 85)),
                line((70, 85), (220, 85)),
            ],
        ),
        Step(
            "Dòng sông uốn lượn",
            "Từ chân núi, bé vẽ hai đường cong chạy xuống phía dưới. Hai đường cách nhau rộng dần sẽ tạo cảm giác dòng sông đang chảy về phía mình.",
            [
                curve((330, 205), (260, 255), (360, 345), color=BLUE),
                curve((355, 205), (330, 260), (470, 345), color=BLUE),
            ],
        ),
        Step(
            "Một cây xanh ở gần",
            "Bé vẽ thân cây bằng hai nét dọc ở bên trái. Phía trên, ghép ba vòng tròn làm tán lá. Cây ở gần có thể to hơn những chi tiết ở xa.",
            [
                polygon([(95, 245), (115, 245), (115, 325), (95, 325)], BROWN),
                ellipse(75, 230, 36, 35, GREEN),
                ellipse(135, 230, 36, 35, GREEN),
                ellipse(105, 190, 40, 38, GREEN),
            ],
        ),
        Step(
            "Hoàn thiện phong cảnh",
            "Bé tô trời nhạt, núi và cây bằng những màu mình thích. Dòng sông có thể màu xanh. Nhớ chừa vài khoảng sáng để bức tranh thoáng và dễ nhìn nhé.",
            [],
        ),
    ]


def cat():
    return [
        Step(
            "Đầu tròn và tai nhọn",
            "Bé vẽ một hình tròn hơi dẹt để làm đầu mèo. Phía trên thêm hai hình tam giác nhỏ. Hai chiếc tai đã giúp mình nhận ra bạn mèo rồi.",
            [
                ellipse(300, 120, 75, 65, CREAM),
                polygon([(235, 85), (245, 20), (285, 57)], CREAM),
                polygon([(315, 57), (355, 20), (365, 85)], CREAM),
            ],
        ),
        Step(
            "Thân và hai bàn chân",
            "Dưới đầu mèo, bé vẽ thân hình bầu dục. Thêm hai hình bầu dục nhỏ ở dưới để làm bàn chân. Chúng mình đang vẽ một bạn mèo ngồi ngoan.",
            [
                ellipse(300, 235, 88, 78, CREAM),
                ellipse(250, 300, 30, 17, CREAM),
                ellipse(350, 300, 30, 17, CREAM),
            ],
        ),
        Step(
            "Mắt, mũi và miệng",
            "Bé đặt hai mắt ở hai bên khuôn mặt. Ở giữa vẽ mũi nhỏ hình tam giác. Từ mũi, kéo hai nét cong ngắn để mèo có nụ cười.",
            [
                ellipse(270, 112, 7, 11, INK),
                ellipse(330, 112, 7, 11, INK),
                polygon([(292, 137), (308, 137), (300, 146)], CORAL),
                curve((300, 146), (285, 170), (275, 151)),
                curve((300, 146), (315, 170), (325, 151)),
            ],
        ),
        Step(
            "Râu và đuôi cong",
            "Hai bên má, bé vẽ mỗi bên ba sợi râu. Ở cạnh thân thêm một chiếc đuôi cong vươn lên. Đuôi mèo không cần thẳng, cong mềm sẽ đáng yêu hơn.",
            [
                line((255, 142), (205, 133)),
                line((255, 151), (200, 154)),
                line((255, 160), (210, 176)),
                line((345, 142), (395, 133)),
                line((345, 151), (400, 154)),
                line((345, 160), (390, 176)),
                curve((380, 255), (500, 245), (445, 180), color=BROWN, width=10),
            ],
        ),
        Step(
            "Thêm nét riêng của mèo",
            "Bé vẽ vài vệt nhỏ trên trán, một mảng lông ở ngực và những ngón chân. Bé có thể thêm chiếc nơ hoặc vòng cổ để bạn mèo có phong cách riêng.",
            [
                line((285, 65), (290, 82)),
                line((300, 62), (300, 82)),
                line((315, 65), (310, 82)),
                curve((265, 205), (300, 230), (335, 205)),
                line((243, 297), (243, 308)),
                line((257, 297), (257, 308)),
                line((343, 297), (343, 308)),
                line((357, 297), (357, 308)),
            ],
        ),
        Step(
            "Tô màu bạn mèo",
            "Bé tô mèo màu vàng nhạt, cam, xám hoặc màu mình thích. Tô nhẹ tay quanh mắt và mũi. Chúng mình đã hoàn thành một bạn mèo vui vẻ rồi.",
            [],
        ),
    ]


def dog():
    return [
        Step(
            "Đầu và tai cụp",
            "Bé vẽ một hình tròn để làm đầu cún. Hai bên thêm hai hình bầu dục dài làm tai cụp. Tai to một chút sẽ làm bạn cún trông rất hiền.",
            [
                ellipse(300, 115, 70, 65, CREAM),
                ellipse(225, 115, 25, 48, BROWN),
                ellipse(375, 115, 25, 48, BROWN),
            ],
        ),
        Step(
            "Thân và bàn chân",
            "Dưới đầu, bé vẽ thân cún bằng một hình bầu dục lớn. Phía dưới là hai bàn chân. Bé nhớ chừa chỗ bên cạnh thân để lát nữa vẽ đuôi nhé.",
            [
                ellipse(300, 235, 92, 75, CREAM),
                ellipse(245, 300, 32, 18, BROWN),
                ellipse(355, 300, 32, 18, BROWN),
            ],
        ),
        Step(
            "Khuôn mặt bạn cún",
            "Bé đặt hai mắt đen nhỏ, rồi vẽ phần mõm bằng một hình bầu dục. Ở giữa mõm là chiếc mũi đen. Thêm một nét cong cho miệng cười.",
            [
                ellipse(270, 105, 7, 10, INK),
                ellipse(330, 105, 7, 10, INK),
                ellipse(300, 145, 37, 26, "#fffaf0"),
                ellipse(300, 132, 12, 8, INK),
                curve((275, 155), (300, 180), (325, 155)),
            ],
        ),
        Step(
            "Lưỡi nhỏ và đuôi vẫy",
            "Dưới miệng, bé vẽ một chiếc lưỡi nhỏ. Bên cạnh thân, kéo một đường cong lên để làm đuôi. Nhìn bạn cún như đang vẫy chào mình vậy.",
            [
                ellipse(300, 171, 9, 14, CORAL),
                curve((389, 245), (465, 225), (430, 180), color=BROWN, width=12),
            ],
        ),
        Step(
            "Vòng cổ và ngón chân",
            "Bé thêm một chiếc vòng cổ bằng nét cong dưới cằm. Vẽ một thẻ tên tròn nhỏ ở giữa và vài nét ngắn trên bàn chân để chia các ngón.",
            [
                curve((252, 179), (300, 205), (348, 179), color=TEAL, width=7),
                ellipse(300, 194, 10, 10, YELLOW),
                line((236, 296), (236, 310)),
                line((252, 296), (252, 310)),
                line((348, 296), (348, 310)),
                line((364, 296), (364, 310)),
            ],
        ),
        Step(
            "Tô màu cho cún",
            "Bé chọn màu cho bộ lông và đôi tai của cún. Có thể tô tai sẫm hơn phần thân để bức tranh rõ nét. Mình nhớ tô cả chiếc vòng cổ xinh nữa nhé.",
            [],
        ),
    ]


def fish():
    scales = [
        curve((x, y - 15), (x + 25, y), (x, y + 15), color=TEAL, width=3)
        for x, y in [(230, 155), (280, 155), (330, 155), (230, 205), (280, 205), (330, 205)]
    ]
    return [
        Step(
            "Thân cá hình bầu dục",
            "Bé vẽ một hình bầu dục nằm ngang ở giữa giấy. Đầu cá ở bên phải, đuôi ở bên trái. Mình để trống hai bên cho vây và đuôi nhé.",
            [ellipse(310, 180, 145, 80, BLUE)],
        ),
        Step(
            "Đuôi hình tam giác",
            "Bé nối một hình tam giác vào đầu nhỏ bên trái. Phần ngoài đuôi có thể xòe rộng. Thêm một nét ở giữa để chiếc đuôi trông như đang quẫy nước.",
            [
                polygon([(170, 180), (65, 250), (65, 110)], TEAL),
                line((75, 180), (160, 180), color=TEAL),
            ],
        ),
        Step(
            "Vây trên và vây dưới",
            "Trên lưng cá, bé vẽ một chiếc vây nhọn. Dưới bụng thêm một chiếc vây nhỏ. Mình dùng những nét ngắn để tạo các nếp vây.",
            [
                polygon([(260, 106), (300, 55), (360, 108)], TEAL),
                polygon([(270, 256), (310, 300), (350, 256)], TEAL),
                line((300, 67), (300, 103)),
                line((320, 78), (330, 105)),
            ],
        ),
        Step(
            "Mắt và miệng",
            "Ở phía đầu cá, bé vẽ một mắt tròn và chấm đen nhỏ bên trong. Kế bên là một nét cong làm miệng. Thêm đường cong ngắn để chia phần mang cá.",
            [
                ellipse(400, 155, 15, 15, "#ffffff"),
                ellipse(404, 155, 7, 7, INK),
                curve((425, 198), (439, 209), (447, 193)),
                curve((375, 122), (345, 180), (375, 240)),
            ],
        ),
        Step(
            "Vảy cá và bong bóng",
            "Bé vẽ vài nét cong nhỏ trên thân để làm vảy. Phía trước miệng thêm những vòng tròn to nhỏ. Đó là các bong bóng nước đang nổi lên.",
            scales
            + [
                ellipse(500, 145, 17, 17, "#d9f2ff"),
                ellipse(530, 100, 11, 11, "#d9f2ff"),
                ellipse(510, 60, 7, 7, "#d9f2ff"),
            ],
        ),
        Step(
            "Tô cá thật rực rỡ",
            "Bé chọn hai màu cho thân và vây cá. Tô nhẹ quanh các đường vảy để mình vẫn nhìn thấy nét vẽ. Cá của bé có thể xanh, cam hoặc tím đều được.",
            [],
        ),
    ]


def rabbit():
    return [
        Step(
            "Đầu tròn và tai dài",
            "Bé vẽ một vòng tròn làm đầu thỏ. Phía trên thêm hai hình bầu dục dài, hẹp. Hai tai dài là đặc điểm rất dễ nhận ra của bạn thỏ.",
            [
                ellipse(300, 150, 70, 65, "#f4efff"),
                ellipse(270, 65, 20, 58, "#f4efff"),
                ellipse(330, 65, 20, 58, "#f4efff"),
            ],
        ),
        Step(
            "Thân và bàn chân",
            "Dưới đầu, bé thêm thân hình bầu dục. Hai bàn chân dài đặt ở phía trước. Thỏ đang ngồi nên thân thấp và tròn một chút nhé.",
            [
                ellipse(300, 250, 90, 65, "#f4efff"),
                ellipse(245, 303, 35, 16, "#f4efff"),
                ellipse(355, 303, 35, 16, "#f4efff"),
            ],
        ),
        Step(
            "Mắt, mũi và má",
            "Bé đặt hai mắt nhỏ trên khuôn mặt. Thêm mũi hình tam giác, miệng cong và hai má tròn. Bé có thể vẽ thỏ đang mỉm cười.",
            [
                ellipse(275, 145, 7, 10, INK),
                ellipse(325, 145, 7, 10, INK),
                polygon([(292, 170), (308, 170), (300, 178)], CORAL),
                curve((300, 178), (285, 197), (277, 183)),
                curve((300, 178), (315, 197), (323, 183)),
                ellipse(252, 170, 12, 7, "#ffc9cf"),
                ellipse(348, 170, 12, 7, "#ffc9cf"),
            ],
        ),
        Step(
            "Tai trong và đuôi bông",
            "Trong mỗi tai, bé vẽ thêm một hình bầu dục nhỏ. Bên cạnh thân là chiếc đuôi tròn như cục bông. Thêm hai nét ngắn ở bàn chân để làm ngón.",
            [
                ellipse(270, 63, 8, 38, "#ffc9cf"),
                ellipse(330, 63, 8, 38, "#ffc9cf"),
                ellipse(205, 260, 23, 23, "#ffffff"),
                line((238, 300), (238, 311)),
                line((350, 300), (350, 311)),
            ],
        ),
        Step(
            "Thêm củ cà rốt",
            "Ở cạnh thỏ, bé vẽ củ cà rốt bằng một hình tam giác dài. Thêm ba nét xanh làm cuống lá. Một vài nét ngắn trên thân cà rốt giúp hình vẽ sinh động hơn.",
            [
                polygon([(440, 215), (475, 240), (415, 305)], "#ffad64"),
                line((455, 222), (460, 195), color=TEAL),
                line((455, 222), (485, 200), color=TEAL),
                line((455, 222), (435, 195), color=TEAL),
                line((435, 250), (450, 257), color=BROWN),
            ],
        ),
        Step(
            "Tô màu thật dịu",
            "Bé tô lông thỏ bằng màu nhạt để mắt và mũi nổi bật. Tai trong có thể màu hồng, cà rốt màu cam và lá màu xanh. Bạn thỏ đã có một món quà rồi.",
            [],
        ),
    ]


def bird():
    return [
        Step(
            "Thân và đầu chim",
            "Bé vẽ thân chim bằng một hình bầu dục. Gần góc phía trên bên phải, thêm một hình tròn nhỏ làm đầu. Đầu và thân chạm nhau để chim trông liền mạch.",
            [ellipse(300, 205, 105, 80, BLUE), ellipse(385, 130, 50, 48, BLUE)],
        ),
        Step(
            "Mỏ nhỏ và mắt tròn",
            "Ở trước đầu, bé thêm một hình tam giác nhỏ làm mỏ. Vẽ mắt tròn gần phía trên mỏ, rồi chừa một chấm trắng nhỏ để mắt trông sáng hơn.",
            [
                polygon([(433, 130), (480, 150), (432, 158)], YELLOW),
                ellipse(395, 120, 8, 9, INK),
                ellipse(397, 117, 2, 2, "#ffffff"),
            ],
        ),
        Step(
            "Cánh chim",
            "Trên thân, bé vẽ một nét cong lớn rồi khép lại thành chiếc cánh. Bên trong cánh thêm vài nét cong nhỏ để gợi những lớp lông xếp lên nhau.",
            [
                curve((340, 190), (260, 140), (230, 225)),
                curve((230, 225), (300, 270), (340, 190)),
                curve((270, 195), (250, 230), (285, 234)),
                curve((300, 199), (285, 230), (312, 226)),
            ],
        ),
        Step(
            "Đuôi xòe",
            "Bên trái thân chim, bé thêm hai nét dài tỏa ra để làm đuôi. Mình nối phần đuôi bằng vài nét xiên. Chiếc đuôi giúp bạn chim giữ thăng bằng.",
            [
                polygon([(200, 205), (120, 150), (140, 220), (120, 250), (210, 240)], TEAL),
                line((142, 181), (195, 216)),
            ],
        ),
        Step(
            "Chân và cành cây",
            "Dưới bụng chim, bé kéo hai nét ngắn làm chân. Mỗi chân thêm vài ngón bám vào một cành cây. Bé có thể vẽ thêm hai chiếc lá ở đầu cành.",
            [
                line((280, 280), (280, 318), (265, 325)),
                line((280, 318), (294, 325)),
                line((330, 280), (330, 318), (315, 325)),
                line((330, 318), (344, 325)),
                line((75, 330), (535, 330), color=BROWN, width=7),
                polygon([(480, 330), (510, 288), (530, 310)], GREEN),
                polygon([(445, 330), (420, 295), (400, 315)], GREEN),
            ],
        ),
        Step(
            "Tô bộ lông nhiều màu",
            "Bé tô thân chim và cánh bằng hai sắc màu khác nhau. Mỏ có thể màu vàng, lá màu xanh và cành màu nâu. Bé thử đặt tên cho bạn chim của mình nhé.",
            [],
        ),
    ]


def lessons():
    basics = "course_basics"
    animals = "course_animals"
    return [
        Lesson(
            "basics_01",
            basics,
            "Vẽ cơ bản",
            1,
            "Nét vẽ đầu tiên",
            "luyện nét thẳng, nét cong và hình tròn",
            "Vẽ ba nét ngang, ba nét dọc, hai nét xiên và một mặt trời từ hình tròn. Chụp ảnh bài vẽ để nộp.",
            basic_strokes(),
        ),
        Lesson(
            "basics_02",
            basics,
            "Vẽ cơ bản",
            2,
            "Phối màu",
            "nhận biết màu và thử pha màu cơ bản",
            "Tạo bảng màu đỏ, vàng, xanh dương; thử pha cam, xanh lá, tím và tô một bông hoa nhỏ. Chụp ảnh bài thực hành.",
            colors(),
        ),
        Lesson(
            "basics_03",
            basics,
            "Vẽ cơ bản",
            3,
            "Vẽ ngôi nhà từ hình cơ bản",
            "ghép tam giác và chữ nhật thành ngôi nhà",
            "Vẽ một ngôi nhà có mái, cửa ra vào, hai cửa sổ và lối đi. Tô màu theo ý thích rồi nộp ảnh.",
            house(),
        ),
        Lesson(
            "basics_04",
            basics,
            "Vẽ cơ bản",
            4,
            "Vẽ bông hoa",
            "vẽ hoa bằng hình tròn và những nét cong",
            "Vẽ một bông hoa có nhụy, sáu cánh, cuống và lá. Có thể thêm hoa nhỏ hoặc cỏ xung quanh. Tô màu và nộp ảnh.",
            flower(),
        ),
        Lesson(
            "basics_05",
            basics,
            "Vẽ cơ bản",
            5,
            "Vẽ phong cảnh đơn giản",
            "sắp xếp trời, núi, cây và dòng sông",
            "Vẽ phong cảnh có đường chân trời, hai ngọn núi, mặt trời, cây và dòng sông. Tô màu, đặt tên tranh và nộp ảnh.",
            landscape(),
        ),
        Lesson(
            "animals_01",
            animals,
            "Vẽ động vật",
            1,
            "Vẽ mèo",
            "vẽ bạn mèo từ hình tròn và hình bầu dục",
            "Vẽ mèo ngồi có hai tai nhọn, mắt, mũi, râu, chân và đuôi. Chọn màu lông mình thích rồi nộp ảnh bài vẽ.",
            cat(),
        ),
        Lesson(
            "animals_02",
            animals,
            "Vẽ động vật",
            2,
            "Vẽ chó con",
            "vẽ bạn cún với tai cụp và chiếc đuôi cong",
            "Vẽ một chú chó có tai cụp, khuôn mặt vui vẻ, bàn chân và vòng cổ. Tô màu và chụp ảnh nộp bài.",
            dog(),
        ),
        Lesson(
            "animals_03",
            animals,
            "Vẽ động vật",
            3,
            "Vẽ cá nhỏ",
            "vẽ cá bằng hình bầu dục và tam giác",
            "Vẽ cá có đuôi, vây, mắt, miệng và vài chiếc vảy. Thêm bong bóng nước, tô màu và nộp ảnh bài vẽ.",
            fish(),
        ),
        Lesson(
            "animals_04",
            animals,
            "Vẽ động vật",
            4,
            "Vẽ thỏ và cà rốt",
            "vẽ thỏ có tai dài cùng một củ cà rốt",
            "Vẽ thỏ có hai tai dài, mắt mũi, chân và đuôi tròn. Thêm củ cà rốt, tô màu và nộp ảnh.",
            rabbit(),
        ),
        Lesson(
            "animals_05",
            animals,
            "Vẽ động vật",
            5,
            "Vẽ chim trên cành",
            "vẽ chim với cánh, đuôi và đôi chân nhỏ",
            "Vẽ chim đứng trên cành có đầu, mỏ, mắt, cánh, đuôi và chân. Tô màu, đặt tên cho bạn chim và nộp ảnh.",
            bird(),
        ),
    ]
