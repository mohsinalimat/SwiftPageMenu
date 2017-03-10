//
//  PageMenuController.swift
//  SwiftPager
//
//  Created by Tamanyan on 3/9/17.
//  Copyright © 2017 Tamanyan. All rights reserved.
//

import UIKit

open class PageMenuController: UIViewController {
    /// SwiftPager configurations
    open let options: PageMenuOptions

    open weak var dataSource: PageMenuControllerDataSource? {
        didSet {
            self.reloadPages(reloadViewControllers: true)
        }
    }

    open weak var delegate: PageMenuControllerDelegate?

    /// The view controllers that are displayed in the page view controller.
    open internal(set) var viewControllers: [UIViewController]?

    /// The tab menu titles that are displayed in the page view controller.
    open internal(set) var menuTitles: [String]?

    var currentIndex: Int? {
        guard let viewController = self.pageViewController.selectedViewController else {
            return nil
        }
        return self.viewControllers?.index(of: viewController)
    }

    fileprivate lazy var pageViewController: EMPageViewController = {
        let vc = EMPageViewController(navigationOrientation: .horizontal)

        vc.view.backgroundColor = .clear
        vc.dataSource = self
        vc.delegate = self
        vc.scrollView.backgroundColor = .clear
        vc.automaticallyAdjustsScrollViewInsets = false

        return vc
    }()

    fileprivate lazy var tabView: TabMenuView = {
        let tabView = TabMenuView(options: self.options)

        tabView.pageItemPressedBlock = { [weak self] (index: Int, direction: EMPageViewControllerNavigationDirection) in
            self?.displayControllerWithIndex(index, direction: direction, animated: true)
        }

        return tabView
    }()

    fileprivate var beforeIndex: Int = 0

    public var isInfinite: Bool {
        return self.options.isInfinite
    }

    fileprivate var pageCount: Int {
        return self.viewControllers?.count ?? 0
    }

    fileprivate var tabItemCount: Int {
        return self.dataSource?.menuTitles(forPageMenuController: self).count ?? 0
    }

    public init(options: PageMenuOptions? = nil) {
        self.options = options ?? DefaultPageMenuOption()
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.setup()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let currentIndex = self.currentIndex, self.isInfinite {
            self.tabView.updateCurrentIndex(currentIndex, shouldScroll: true)
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tabView.layouted = true
    }
}


// MARK: - Public Interface

public extension PageMenuController {
    public func displayControllerWithIndex(_ index: Int, direction: EMPageViewControllerNavigationDirection, animated: Bool) {
        guard let viewControllers = self.viewControllers else {
            return
        }

        if self.pageViewController.scrolling {
            return
        }

        if self.pageViewController.selectedViewController == viewControllers[index] {
            return
        }

        self.beforeIndex = index
        self.pageViewController.delegate = nil
        self.tabView.updateCollectionViewUserInteractionEnabled(false)

        let completion: ((Bool) -> Void) = { [weak self] _ in
            self?.beforeIndex = index
            self?.pageViewController.delegate = self
            self?.tabView.updateCollectionViewUserInteractionEnabled(true)
        }

        self.pageViewController.selectViewController(
            viewControllers[index],
            direction: direction,
            animated: animated,
            completion: completion)

        guard self.isViewLoaded else { return }
        self.tabView.updateCurrentIndex(index, shouldScroll: true)
    }
}


// MARK: - View

extension PageMenuController {
    fileprivate func reloadPages(reloadViewControllers: Bool) {
        if let titles = self.dataSource?.menuTitles(forPageMenuController: self) {
            self.tabView.pageTabItems = titles
            self.tabView.updateCurrentIndex(self.beforeIndex, shouldScroll: true, animated: false)
        }

        if reloadViewControllers || self.viewControllers == nil {
            self.viewControllers = self.dataSource?.viewControllers(forPageMenuController: self)
        }

        let defaultIndex = self.dataSource?.defaultPageIndex(forPageMenuController: self) ?? 0

        guard defaultIndex < self.viewControllers?.count ?? 0,
            let viewController = self.viewControllers?[defaultIndex] else {
                return
        }

        self.pageViewController.selectViewController(
            viewController,
            direction: .forward,
            animated: false,
            completion: nil)
    }

    fileprivate func setup() {
        self.view.addSubview(self.pageViewController.view)
        self.view.addSubview(self.tabView)

        self.pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.tabView.translatesAutoresizingMaskIntoConstraints = false

        switch self.options.tabMenuPosition {
        case .top:
            // setup page view controller layout
            self.pageViewController.view.topAnchor.constraint(equalTo: self.tabView.bottomAnchor).isActive = true
            self.pageViewController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            self.pageViewController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            self.pageViewController.view.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true

            // setup tab view layout
            self.tabView.heightAnchor.constraint(equalToConstant: options.menuItemSize.height).isActive = true
            self.tabView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
            self.tabView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            self.tabView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        case .bottom:
            // setup page view controller layout
            self.pageViewController.view.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
            self.pageViewController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            self.pageViewController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            self.pageViewController.view.bottomAnchor.constraint(equalTo: self.tabView.topAnchor).isActive = true

            // setup tab view layout
            self.tabView.heightAnchor.constraint(equalToConstant: options.menuItemSize.height).isActive = true
            self.tabView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
            self.tabView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            self.tabView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        }

        self.view.sendSubview(toBack: self.pageViewController.view)
        self.pageViewController.didMove(toParentViewController: self)
    }
}

// MARK:- EMPageViewControllerDelegate

extension PageMenuController: EMPageViewControllerDelegate {
    public func em_pageViewController(_ pageViewController: EMPageViewController, willStartScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController, direction: EMPageViewControllerNavigationDirection) {
        // Order to prevent the the hit repeatedly during animation
        self.tabView.updateCollectionViewUserInteractionEnabled(false)
        self.delegate?.pageMenuViewController(self, willScrollToPageAtIndex: self.currentIndex ?? 0, direction: direction)
    }

    public func em_pageViewController(_ pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController: UIViewController, direction: EMPageViewControllerNavigationDirection, transitionSuccessful: Bool) {
        if let currentIndex = self.currentIndex , currentIndex < self.tabItemCount {
            self.tabView.updateCurrentIndex(currentIndex, shouldScroll: true)
            self.beforeIndex = currentIndex
            self.delegate?.pageMenuViewController(self, didScrollToPageAtIndex: currentIndex, direction: direction)
        }

        self.tabView.updateCollectionViewUserInteractionEnabled(true)
    }

    public func em_pageViewController(_ pageViewController: EMPageViewController, isScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController?, direction: EMPageViewControllerNavigationDirection, progress: CGFloat) {
        var index: Int
        if progress > 0 {
            index = self.beforeIndex + 1
        } else {
            index = self.beforeIndex - 1
        }

        if index == self.tabItemCount {
            index = 0
        } else if index < 0 {
            index = self.tabItemCount - 1
        }

        let scrollOffsetX = self.view.frame.width * progress
        self.tabView.scrollCurrentBarView(index, contentOffsetX: scrollOffsetX, progress: progress)
        self.delegate?.pageMenuViewController(self, scrollingProgress: progress, direction: direction)
    }

    public func em_pageViewController(_ pageViewController: EMPageViewController, willStartScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController) {
    }

    public func em_pageViewController(_ pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) {
    }

    public func em_pageViewController(_ pageViewController: EMPageViewController, isScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController?, progress: CGFloat) {
    }
}

// MARK:- EMPageViewControllerDataSource

extension PageMenuController: EMPageViewControllerDataSource {
    private func nextViewController(_ viewController: UIViewController, isAfter: Bool) -> UIViewController? {
        guard let viewControllers = self.viewControllers, var index = viewControllers.index(of: viewController) else {
            return nil
        }

        if isAfter {
            index += 1
        } else {
            index -= 1
        }

        if self.isInfinite {
            if index < 0 {
                index = viewControllers.count - 1
            } else if index == viewControllers.count {
                index = 0
            }
        }

        if index >= 0 && index < viewControllers.count {
            return viewControllers[index]
        }
        return nil
    }

    public func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController, isAfter: true)
    }

    public func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController, isAfter: false)
    }
}
