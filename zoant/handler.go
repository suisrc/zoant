package app

// 这是一个测试类， 需要屏蔽 init 函数

import (
	"encoding/base64"
	"encoding/json"
	"flag"
	"net/http"

	"github.com/suisrc/zoo"
	"github.com/suisrc/zoo/zoc"
	"github.com/suisrc/zoo/zoe/wsz"
)

// 通过 init 加载应用配置，注册方法等
func init() { Load() }

var (
	G = struct {
		Config Config `json:"zoant"`
	}{}
)

type Config struct {
	Path string `json:"path"`
}

func Load() {
	zoo.Register("50-hello", &G, register)
	flag.StringVar(&G.Config.Path, "apath", "hello", "访问路径")
}

// 注册回调函数，返回一个关闭函数，用于资源清理等
func register(svc zoo.SvcKit) zoo.Closed {
	hdl := zoo.Inject(svc, &HelloHandler{})
	hdl.WS = wsz.NewHandler(hdl.NewHook, 1)
	svc.Router(G.Config.Path, hdl.hello)
	svc.Router("ws", hdl.wsworker)
	svc.Router("", hdl.hello)
	// hdl := svc.Get("HelloHandler").(*HelloHandler)
	zoo.GET("world", hdl.world, svc)
	zoo.GET("token", zoo.TokenAuth(zoo.Ptr("123"), hdl.token), svc)
	return func() {
		zoc.Logn("hello closed")
	}
}

type HelloHandler struct {
	FA any        // 标记不注入，默认
	FB any        `svckit:"-"`         // 标记不注入，默认
	SK zoo.SvcKit `svckit:"type"`      // 根据类型自动注入
	AH any        `svckit:"hdl-hello"` // 根据名称自动注入
	AW any        `svckit:"server"`    // 根据名称自动注入
	TK zoo.TplKit `svckit:"auto"`      // 根据名称自动注入
	WS http.Handler
}

func (aa *HelloHandler) hello(zrc *zoo.Ctx) {
	zrc.JSON(&zoo.Result{Success: true, Data: "hello!", ErrShow: 1})
}

func (aa *HelloHandler) world(zrc *zoo.Ctx) {
	zrc.JSON(&zoo.Result{Success: true, Data: "world!"})
}

func (aa *HelloHandler) token(zrc *zoo.Ctx) {
	zrc.JSON(&zoo.Result{Success: true, Data: "token!"})
}

func (aa *HelloHandler) wsworker(zrc *zoo.Ctx) {
	aa.WS.ServeHTTP(zrc.Writer, zrc.Request)
}

func (hdl *HelloHandler) NewHook(key string, req *http.Request, sender wsz.SendFunc, cancel func()) (string, wsz.Hook, error) {
	return key, hdl, nil
}

// wsz.Hook 接口实现
func (hdl *HelloHandler) Close() error {
	return nil
}

func (hdl *HelloHandler) Receive(code byte, data []byte) (byte, []byte, error) {
	if bts, err := base64.StdEncoding.DecodeString(string(data)); err == nil {
		data = bts // 解码成功，使用解码后的数据
	}
	rmap := map[string]any{}
	if err := json.Unmarshal(data, &rmap); err != nil {
		zoc.Logn("[_zooant_]: [not json]", string(data))
		return 0, nil, nil
	}
	delete(rmap, "level")
	delete(rmap, "time")
	zoc.Logn("[_zooant_]:", zoc.ToStrText(rmap, "Description", "message"))
	return 0, nil, nil
}
