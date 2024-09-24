function createShootingStar() {
    const shootingStar = document.createElement('div');
    shootingStar.classList.add('shooting-star');

    // 设置随机位置
    shootingStar.style.left = `${Math.random() * window.innerWidth}px`;
    shootingStar.style.top = `${Math.random() * window.innerHeight}px`;

    document.body.appendChild(shootingStar);

    // 2秒后删除流星
    setTimeout(() => {
        shootingStar.remove();
    }, 2000);
}

// 每隔一定时间生成一个新的流星
setInterval(createShootingStar, 1000);
